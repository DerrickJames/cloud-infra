#!/usr/bin/env bash
set -euo pipefail

#######################
# AWS Helpers
#######################


# Global cache vars
CLOUD_IAM_USER_ID=""
CLOUD_IAM_ACCOUNT_ID=""
CLOUD_IAM_ARN=""
CLOUD_IAM_IDENTITY_INITIALIZED=0

# Resolve IAM identity and cache the results
cloud_iam_resolve_identity() {
  if [[ "${CLOUD_IAM_IDENTITY_INITIALIZED:-0}" -ne 0 ]]; then
    return 0
  fi

  CLOUD_IAM_IDENTITY_INITIALIZED=2

  local identity

  if ! identity="$(aws sts get-caller-identity --output json 2>/dev/null)"; then
    echo "Warning: Failed to resolve IAM identity: $identity" >&2
    return 1
  fi

  CLOUD_IAM_USER_ID=$(printf '%s' "$identity" | jq -r '.UserId')
  CLOUD_IAM_ACCOUNT_ID=$(printf '%s' "$identity" | jq -r '.Account')
  CLOUD_IAM_ARN=$(printf '%s' "$identity" | jq -r '.Arn')
  CLOUD_IAM_IDENTITY_INITIALIZED=1

  return 0
}


# Start SSM session to target
start_ssm_session() {
  log_message "INFO" "Starting SSM session to target: 'Environment=$ENVIRONMENT, Instance=$INSTANCE_ID'"

  aws ssm start-session --target "$INSTANCE_ID"
}

# Start SSM port forwarding session
start_rds_tunnel() {
  log_message "INFO" "Starting RDS tunnel to target: 'Environment=$ENVIRONMENT, Instance=$INSTANCE_ID, RDS_Endpoint=$RDS_ENDPOINT'"

  aws ssm start-session \
    --target "$INSTANCE_ID" \
    --document-name "AWS-StartPortForwardingSessionToRemoteHost" \
    --parameters "host=$RDS_ENDPOINT,portNumber=$REMOTE_PORT,localPortNumber=$LOCAL_PORT"
}

# Find a running EC2 instance by tags
find_ec2_instance_by_tag() {
  log_message "INFO" "Looking up EC2 instance: 'Environment=$ENVIRONMENT'"

  INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:${EC2_TAG_KEY},Values=${EC2_TAG_VALUE}" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text || true)

  if [[ -z "$INSTANCE_ID" || "$INSTANCE_ID" == "None" ]]; then
    log_message "ERROR" "No running EC2 instance found: 'Environment=$ENVIRONMENT'"
    exit 1
  fi 

  log_message "INFO" "Found EC2 instance: 'Environment=$ENVIRONMENT, Instance=$INSTANCE_ID'" 
}

# Find an RDS endpoint by tags
find_rds_endpoint_by_tag() {
  # info "🔍  Looking up Aurora RDS cluster for env '$ENVIRONMENT' using tag: ${RDS_TAG_KEY}=${RDS_TAG_VALUE} ..."
  log_message "INFO" "Looking up Aurora RDS cluster: 'Environment=$ENVIRONMENT'"

  # Get all cluster ARNs + Endpoints
  local clusters
  clusters=$(aws rds describe-db-clusters \
    --query 'DBClusters[].{Arn:DBClusterArn,Endpoint:Endpoint}' \
    --output text 2>&1) || {
      error_msg=$(echo "$clusters" | jq -Rs .)
      log_message "ERROR" "Failed to describe RDS clusters: '$error_msg'"
      exit 1
    }

  if [[ -z "$clusters" ]]; then
    log_message "ERROR" "No RDS DB clusters found"
    exit 1
  fi

  # Each line: <ARN><space><Endpoint>
  while read -r ARN ENDPOINT; do
    [[ -z "$ARN" ]] && continue

    # Check tags on this cluster
    local matches
    matches=$(aws rds list-tags-for-resource \
      --resource-name "$ARN" \
      --query "TagList[?Key=='${RDS_TAG_KEY}' && Value=='${RDS_TAG_VALUE}'] | length(@)" \
      --output text 2>&1) || {
        error_msg=${matches//$'\n'/}
        log_message "ERROR" "Failed to list tags for RDS cluster: '$error_msg'"
        exit 1
      }

    if [[ "$matches" != "0" && "$matches" != "None" ]]; then
      RDS_ENDPOINT="$ENDPOINT"
      log_message "INFO" "Found RDS cluster endpoint: ${RDS_ENDPOINT}"
      return 0
    fi
  done <<< "$clusters"

  log_message "ERROR" "No RDS DB cluster found: 'Environment=$ENVIRONMENT'"
  exit 1
}
