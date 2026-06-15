#!/usr/bin/env bash
set -euo pipefail

##########################
#   EC2 Connect Plugin
##########################

# Guard to explicitly forbid direct execution
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "This script '$0' is a cloud plugin and cannot be run directly."
  exit 1
fi

# EC2 instances to use as SSM bridge:
#   e.g. tag: Environment = dev|staging|prod
EC2_TAG_KEY="Environment"

# Display script usage
ec2_connect_usage() {
  echo "-----------------------"
  echo "|     Cloud CLI      |"
  echo "-----------------------"
  echo
  echo -e "${YELLOW}Usage:${RESET}"
  echo "  cloud ec2-connect <environment>"
  echo
  echo -e "${YELLOW}Arguments:${RESET}"
  printf "  ${GREEN}%-15s${RESET} %s\n" "environment" "Environment to connect"
  echo
  echo -e "${YELLOW}Help:${RESET}"
  echo "Environments expected: dev | staging | prod"
  echo
  echo -e "${YELLOW}Examples:${RESET}"
  echo "  cloud ec2-connect dev"
  echo "  cloud ec2-connect staging"
  exit 1
}

# Parse script arguments
parse_ec2_args() {
  if [[ "$#" -lt 1 ]]; then
    ec2_connect_usage
  fi

  ENVIRONMENT="${1:-}"

  if [[ -z "$ENVIRONMENT" ]]; then
    ec2_connect_usage
    return 1
  fi

  export AWS_PROFILE="ssm-$ENVIRONMENT"
}

# Map environment to tag values for EC2.
map_ec2_env_to_tags() {
  local env="$1"

  case "$env" in
    dev)
      EC2_TAG_VALUE="dev"
      ;;
    staging)
      EC2_TAG_VALUE="staging"
      ;;
    prod)
      EC2_TAG_VALUE="prod"
      ;;
    *)
      ec2_connect_usage
      ;;
  esac
}

# Main plugin execution
ec2_connect_cmd() {
  parse_ec2_args "$@"
  map_ec2_env_to_tags "$ENVIRONMENT"
  find_ec2_instance_by_tag

  echo
  echo "---------------------------------------------"
  echo "|        REMOTE INSTANCE CONNECT            |"
  echo "---------------------------------------------"
  echo
  echo " Environment      : $ENVIRONMENT"
  echo " AWS Profile      : $AWS_PROFILE"
  echo " IAM User ID      : $CLOUD_IAM_USER_ID"
  echo " EC2 Instance ID  : $INSTANCE_ID"
  echo
  echo
  echo " Once connected, switch to the desired user:"
  echo "   sudo su - ec2-user"
  echo "                                           "
  echo "|--------------------------------------------|"
  echo 

  start_ssm_session
}

register_command "ec2-connect" "ec2_connect_cmd" "Start SSM session to target instance"