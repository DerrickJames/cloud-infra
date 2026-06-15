#!/usr/bin/env bash
set -euo pipefail

#######################
# Validation Helpers
#######################

# Check required env variables
#   e.g. check_required_env AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
check_required_env() {
  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      log "ERROR" "Missing required environment variable: $var"
      exit 1
    fi
  done
}

# Check for required commands
#   e.g. require_command jq docker aws
require_command() {
  for cmd in "$@"; do
    if ! command -v "$cmd" &>/dev/null; then
      log "ERROR" "Missing required command: $cmd"
      exit 1
    fi
  done
}