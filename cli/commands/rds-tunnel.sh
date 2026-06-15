#!/usr/bin/env bash
set -euo pipefail

#########################
#   RDS Tunnel Plugin
#########################

# Guard to explicitly forbid direct execution
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "This script '$0' is a cloud plugin and cannot be run directly."
  exit 1
fi

# EC2 instances to use as SSM bridge:
#   e.g. tag: Environment = dev|staging|prod
EC2_TAG_KEY="Environment"

# Aurora DB CLUSTERS to tunnel to:
#   e.g. tag: Environment = dev|staging|prod
RDS_TAG_KEY="Environment"

# Default ports for Aurora MySQL
DEFAULT_LOCAL_PORT=3306
DEFAULT_REMOTE_PORT=3306

# Display script usage
rds_tunnel_usage() {
  echo "-----------------------"
  echo "|     Cloud CLI      |"
  echo "-----------------------"
  echo
  echo -e "${YELLOW}Usage:${RESET}"
  echo "  cloud rds-tunnel <environment> [local-port] [remote-port]"
  echo
  echo -e "${YELLOW}Arguments:${RESET}"
  printf "  ${GREEN}%-15s${RESET} %s\n" "environment" "Environment to connect"
  printf "  ${GREEN}%-15s${RESET} %s\n" "local-port" "Local DB port to connect"
  printf "  ${GREEN}%-15s${RESET} %s\n" "remote-port" "Remote DB port to connect"
  echo
  echo -e "${YELLOW}Help:${RESET}"
  echo "Environments expected: dev | staging | prod"
  echo
  echo -e "${YELLOW}Examples:${RESET}"
  echo "  cloud rds-tunnel dev"
  echo "  cloud rds-tunnel staging 3307 3306"
  exit 1
}

# Parse script arguments
parse_args() {
  if [[ "$#" -lt 1 ]]; then
    rds_tunnel_usage
  fi

  ENVIRONMENT="${1:-}"
  LOCAL_PORT="${2:-$DEFAULT_LOCAL_PORT}"
  REMOTE_PORT="${3:-$DEFAULT_REMOTE_PORT}"

  if [[ -z "$ENVIRONMENT" ]]; then
    rds_tunnel_usage
    return 1
  fi

  export AWS_PROFILE="ssm-$ENVIRONMENT"
}

# Map environment to tag values for EC2 and RDS.
map_env_to_tags() {
  local env="$1"

  case "$env" in
    dev)
      EC2_TAG_VALUE="dev"
      RDS_TAG_VALUE="dev"
      ;;
    staging)
      EC2_TAG_VALUE="staging"
      RDS_TAG_VALUE="dev"
      ;;
    prod)
      EC2_TAG_VALUE="prod"
      RDS_TAG_VALUE="prod"
      ;;
    *)
      rds_tunnel_usage
      ;;
  esac
}

# Main plugin execution
rds_tunnel_cmd() {
  parse_args "$@"

  if cloud_is_port_in_use "$LOCAL_PORT"; then
    exit 1
  fi

  map_env_to_tags "$ENVIRONMENT"
  find_ec2_instance_by_tag
  find_rds_endpoint_by_tag

  echo "--------------------------------------------------------------"
  echo "|                   RDS TUNNEL CONNECT                       |"
  echo "--------------------------------------------------------------"
  echo
  echo " Environment      : $ENVIRONMENT"
  echo " AWS Profile      : $AWS_PROFILE"
  echo " IAM User ID      : $CLOUD_IAM_USER_ID"
  echo " EC2 Instance ID  : $INSTANCE_ID"
  echo " RDS Endpoint     : $RDS_ENDPOINT"
  echo " Remote Port      : $REMOTE_PORT"
  echo " Local Port       : $LOCAL_PORT"
  echo
  echo " Once connected, open a NEW terminal and run (Aurora MySQL):"
  echo "   mysql -h 127.0.0.1 -P $LOCAL_PORT -u <db_user> -p"
  echo
  echo "|------------------------------------------------------------|"
  echo

  start_rds_tunnel
}

register_command "rds-tunnel" "rds_tunnel_cmd" "Open SSM tunnel to RDS"