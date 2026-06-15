#!/usr/bin/env bash
set -euo pipefail

####################
# Logging Helpers
####################

# Logger with timestamps
#   e.g. log "INFO" "Deployment started"
#       
LOG_FILE="${LOG_DIR}/cloud.log"

log_message() {
  local level="$1"
  shift
  local timestamp
  timestamp=$(date "+%Y-%m-%d %H:%M:%S")

  if [[ "${CLOUD_IAM_IDENTITY_INITIALIZED:-0}" -eq 0 ]]; then
    cloud_iam_resolve_identity || true
  fi

  local prefix

  if [[ "${CLOUD_IAM_IDENTITY_INITIALIZED:-0}" -eq 1 && -n "${CLOUD_IAM_USER_ID:-}" ]]; then
    prefix="[$timestamp] [$level] [$CLOUD_IAM_USER_ID]"
  else
    prefix="[$timestamp] [$level]"
  fi

  echo -e "$prefix $*" | tee -a "$LOG_FILE"
}