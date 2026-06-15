# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Infrastructure-as-Code for the **Cloud** application. Manages AWS infrastructure via Terraform, server configuration via Ansible, and provides a CLI tool (`cloud`) for operations across environments (dev, staging, prod).

## Repository Structure

```
terraform/
  bootstrap/        # One-time setup: S3/DynamoDB state backend, GitHub OIDC role
  envs/staging/     # Environment composition (calls modules)
  modules/          # Reusable modules: vpc, ec2, alb, iam, s3, dynamodb
ansible/
  deploy-docker.yaml       # Rolling Docker deployment playbook
  group_vars/aws_ec2.yaml  # SSM-based connection config (no SSH keys)
  conf.d/default.conf      # Nginx reverse proxy config
cli/
  bin/cloud           # Main CLI entry point
  commands/         # Subcommands: deploy, ec2-connect.sh, rds-tunnel.sh
  lib/              # Shared bash libraries: aws.sh, logging.sh, utils.sh, validation.sh
```

## Terraform

### State Backend (bootstrap first, once per account)

```bash
cd terraform/bootstrap/backend && terraform init && terraform apply
cd terraform/bootstrap/github-oidc && terraform init && terraform apply
```

### Provision / Update Infrastructure

```bash
cd terraform/envs/staging
terraform init -backend-config="config.s3.tfbackend"
terraform plan -var-file="env.public.tfvars"
terraform apply -var-file="env.public.tfvars"
```

- Remote state: S3 bucket + DynamoDB lock table (provisioned by bootstrap)
- AWS Provider: `~> 6.20`, Terraform: `~> 1.5.7`
- EC2 instances are placed in randomly selected private subnets on each apply

### Module Conventions

- Each module has: `main.tf`, `variables.tf`, `outputs.tf`, and often `data.tf` / `providers.tf`
- All new modules must be wired through `envs/<env>/main.tf`
- EBS volumes use encryption by default

## Ansible

### Run Deployment Playbook

```bash
ansible-playbook ansible/deploy-docker.yaml \
  --extra-vars "docker_username=${{ secrets.GC_REGISTRY_USERNAME }} docker_password=${{ secrets.GC_REGISTRY_TOKEN }} docker_image=${{ needs.build.outputs.image}}"
```

- Uses AWS SSM connection plugin — no SSH keys or bastion needed
- Dynamic inventory via `aws_ec2` plugin (configured in `group_vars/aws_ec2.yaml`)
- Performs rolling deployment: pulls new image, swaps container, updates Nginx upstream, prunes old containers
- Skips restart if running container image SHA matches the new image

## CLI (`cloud`)

### Usage

```bash
./cli/bin/cloud <command> [args]
```

| Command                                             | Description                            |
| --------------------------------------------------- | -------------------------------------- |
| `cloud ec2-connect <env>`                           | Open SSM session to an EC2 instance    |
| `cloud rds-tunnel <env> [local-port] [remote-port]` | Tunnel to RDS via SSM port forwarding  |
| `cloud deploy <env> <image-tag>`                    | Deploy a container image (legacy path) |

- AWS profiles must be configured: `ssm-dev`, `ssm-staging`, `ssm-prod`
- CLI logs written to `cli/logs/cloud.log` with timestamps and calling IAM user
- Bash strict mode (`set -euo pipefail`) used throughout

## AWS Architecture

- **Networking**: VPC `10.0.0.0/16` with 2 public + 2 private subnets, NAT Gateway for private egress
- **Compute**: EC2 in private subnets; all access via SSM (no public IPs, no SSH key pairs)
- **Load Balancing**: ALB terminates HTTPS (ACM cert), redirects HTTP → HTTPS; health check on `/api-tools/swagger`
- **DNS**: Route53 A-record aliased to ALB
- **App Stack**: Nginx (reverse proxy) → Docker containers (APP API, Laminas/Zend-based)
- **Cron**: Skill action reminders run every 30 min via `./vendor/bin/laminas`

## Key Conventions

- All access to EC2 is through AWS SSM — never configure SSH key pairs or open port 22
- Nginx config lives in `ansible/conf.d/` and is templated onto the host during deployment
- The `aws_ec2` dynamic inventory group is always named `aws_ec2`; filtering is done via tags in `group_vars`
- Container images are pulled from `ghcr.io`; deployments compare image SHAs to avoid unnecessary restarts
