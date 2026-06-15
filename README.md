# cloud-infra

Infrastructure-as-Code for the **Cloud** application. Manages AWS infrastructure via Terraform, automates server configuration and rolling deployments via Ansible, and provides a `cloud` CLI for day-to-day operations across dev, staging, and prod environments.

**Built with:** Terraform · Ansible · Bash · AWS (EC2, ALB, RDS, SSM, S3, DynamoDB, Route53, IAM)

---

## Architecture

```
GitHub Actions ──OIDC──► AWS IAM Role
                                │
                    ┌───────────▼────────────┐
Internet ──HTTPS──► ALB (ACM cert, 443/80)   │
                    └───────────┬────────────┘
                                │ port 80
                    ┌───────────▼────────────┐
                    │  EC2 (private subnet)   │
                    │  Nginx (reverse proxy)  │
                    │    └── App container    │
                    └───────────┬────────────┘
                                │
                    ┌───────────▼────────────┐
                    │  RDS Aurora (private)   │
                    └────────────────────────┘

SSM Session Manager ──► EC2  (no SSH, no public IP)
```

---

## Repository Structure

```
terraform/
  bootstrap/
    backend/          # One-time: S3 bucket + DynamoDB table for remote state
    github-oidc/      # One-time: GitHub Actions OIDC provider + IAM role
  envs/
    staging/          # Environment composition — calls all modules
  modules/
    vpc/              # VPC, subnets, IGW, NAT Gateway, route tables, security groups
    ec2/              # EC2 instance with randomised subnet placement, encrypted EBS
    alb/              # ALB, HTTPS listener, HTTP→HTTPS redirect, Route53 A-record
    iam/
      ec2-ssm-role/   # IAM role + instance profile for SSM Session Manager
      github-actions-role/  # OIDC-based role for GitHub Actions federation
    s3/               # Versioned, KMS-encrypted S3 bucket (used for state)
    dynamodb/         # DynamoDB table for Terraform state locking

ansible/
  deploy-docker.yaml      # Rolling Docker deployment playbook
  group_vars/aws_ec2.yaml # Dynamic inventory config (SSM-based, no SSH keys)
  conf.d/default.conf     # Nginx reverse proxy config (templated onto host)

cli/
  bin/cloud           # Main CLI entry point
  commands/
    deploy            # Pull image, swap container, reload Nginx
    ec2-connect.sh    # Open SSM session to an EC2 instance
    rds-tunnel.sh     # SSM port-forward to RDS Aurora
  lib/
    aws.sh            # AWS API helpers: SSM sessions, EC2/RDS lookups, IAM identity
    logging.sh        # Timestamped logging to stdout + cli/logs/cloud.log
    utils.sh          # retry, load_config, confirm, wrap_with_timer, port check
    validation.sh     # require_command, check_required_env
    colors.sh         # ANSI color helpers for terminal output
```

---

## Prerequisites

| Tool | Purpose |
|---|---|
| `terraform` >= 1.5.7 | Provision infrastructure |
| `ansible` | Run deployment playbook |
| `aws` CLI | All AWS operations |
| `jq` | JSON parsing in CLI commands |
| `docker` | Local image pulls (legacy deploy path) |

Configure AWS profiles before using the CLI:

```
~/.aws/config
  [profile ssm-dev]
  [profile ssm-staging]
  [profile ssm-prod]
```

---

## Getting Started

### Step 1 — Bootstrap (once per AWS account)

Creates the S3 + DynamoDB backend for remote Terraform state, and the GitHub Actions OIDC role.

```bash
cd terraform/bootstrap/backend
terraform init && terraform apply

cd terraform/bootstrap/github-oidc
terraform init && terraform apply
```

### Step 2 — Provision Staging

```bash
cd terraform/envs/staging
terraform init -backend-config="config.s3.tfbackend"
terraform plan -var-file="env.public.tfvars"
terraform apply -var-file="env.public.tfvars"
```

---

## Ansible — Rolling Deployment

```bash
ansible-playbook ansible/deploy-docker.yaml \
  --extra-vars "docker_username=<user> docker_password=<token> docker_image=<image>"
```

The playbook performs a zero-downtime rolling update:

1. Installs Docker, Python Docker SDK, cronie, and logrotate (idempotent)
2. Creates the `appName` Docker bridge network
3. Pulls the new image from `ghcr.io`; skips deployment if running container already matches the new image SHA
4. Launches a new timestamped container (e.g. `appName1736363323`)
5. Updates the Nginx upstream config to point to the new container
6. Tests Nginx config, reloads via `kill -HUP 1` if valid
7. Stops and removes the old container; prunes dangling images
8. Configures a cron job (every 30 min) for skill action reminders inside the app container
9. Sets up logrotate for the reminders log

---

## CLI Tool (`cloud`)

```bash
./cli/bin/cloud <command> [args]
```

| Command | Description |
|---|---|
| `cloud ec2-connect <env>` | Open an SSM shell session to an EC2 instance |
| `cloud rds-tunnel <env> [local-port] [remote-port]` | SSM port-forward to RDS Aurora (default ports: 3306/3306) |
| `cloud deploy <env> <image-tag>` | Pull and deploy a container image (legacy path) |

Supported environments: `dev`, `staging`, `prod`

Logs are written to `cli/logs/cloud.log` with timestamps and the calling IAM user identity.

---

## Terraform Modules Reference

| Module | Key Resources |
|---|---|
| `modules/vpc` | VPC (10.0.0.0/16), public + private subnets across 3 AZs, IGW, NAT Gateway, route tables, security groups |
| `modules/ec2` | EC2 instance placed in a randomly selected private subnet, encrypted root EBS volume, IAM instance profile required |
| `modules/alb` | Application Load Balancer in public subnets, HTTPS listener with ACM cert, HTTP→HTTPS redirect, Route53 A-record |
| `modules/iam/ec2-ssm-role` | IAM role + instance profile granting SSM Session Manager access to EC2 |
| `modules/iam/github-actions-role` | OIDC provider for GitHub Actions + federated IAM role |
| `modules/s3` | Versioned S3 bucket with KMS encryption, public-access block, 90-day version expiry |
| `modules/dynamodb` | DynamoDB table (`terraform-state-locks`) for state locking, on-demand billing |

---

## Key Conventions

- **No SSH.** All EC2 access is through AWS SSM Session Manager. Never configure SSH key pairs or open port 22.
- **EBS encryption.** Root volumes use encryption by default.
- **Naming.** Resources follow `{project}-{env}-{role}-{resource-type}` (e.g. `appName-staging-api-vpc`).
- **Tagging.** All resources carry: `Project`, `Environment`, `Role`, `ManagedBy=terraform`.
- **Container images.** Pulled from `ghcr.io`; deployments compare image SHAs and skip restarts when unchanged.
- **Dynamic inventory.** Ansible uses the `aws_ec2` plugin; the inventory group is always named `aws_ec2`, filtered by tags in `group_vars/aws_ec2.yaml`.
