#!/usr/bin/env bash
set -euo pipefail

####################
# Util Helpers
####################

# Retry commands with exponential backoff
#   e.g. retry 5 curl -sf http://localhost:8080/healthz
retry() {
  local retries="$1"; shift
  local count=0 exit_code=0
  until "$@"; do
    exit_code=$?
    ((count++))
    if ((count >= retries)); then
      log_message "ERROR" "Command failed after $retries attempts: $*"
      return "$exit_code"
    fi
    log_message "WARN" "Retrying ($count/$retries)..."
    sleep $((count * 2))
  done
}

# Load .env or key-value config files
#   e.g. load_config "./myapp.env"
load_config() {
  local config_file="$1"
  [[ -f "$config_file" ]] || { log_message "ERROR" "Config file not found: $config_file"; return 1; }

  while IFS='=' read -r key value || [[ -n "$key" ]]; do
    [[ "$key" =~ ^\s*# ]] || [[ -z "$key" ]] && continue
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/' | xargs)
    export "$key=$value"
  done < "$config_file"
}

# Move to trash instead of deleting
#   e.g. safe_rm "config.yml"
safe_rm() {
  local file="$1"
  [[ -e "$file" ]] || { log_message "WARN" "File not found: $file"; return 1; }

  local trash_dir="$HOME/.trash"
  mkdir -p "$trash_dir"
  local base
  base=$(basename "$file")
  local timestamp
  timestamp=$(date +%s)
  mv "$file" "$trash_dir/${base}_${timestamp}_$$" && \
    log_message "INFO" "Moved $file to trash instead of deleting"
}

# Prompt for confirmation
#   e.g. if confirm "Are you sure you want to delete production DB?"; then
#           delete_database
#        fi
confirm() {
  local prompt="${1:-Are you sure?} (y/n): "
  while true; do
    read -rn 1 -p "$prompt" response
    echo
    case "${response,,}" in
      y) return 0 ;;
      n) return 1 ;;
      *) echo "Please enter y or n." ;;
    esac
  done
}

# Quick CPU and Memory check
#   e.g. monitor_usage
monitor_usage() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS
      memory=$(top -l 1 | grep PhysMem | awk '{print $2}')
      cpu=$(top -l 1 | grep 'CPU usage' | awk '{gsub(/%/, "", $3); gsub(/%/, "", $5); print $3 + $5}')
  else
      # Linux
      cpu=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}')
      memory=$(free -m | awk '/Mem:/ { printf("%.2f%%", $3/$2 * 100.0) }')
  fi

  echo "CPU: ${cpu}%"
  echo "Memory: ${memory}"
}

# Measure execution time
#   e.g. wrap_with_timer run_long_script
wrap_with_timer() {
  local start end elapsed
  start=$(date +%s)
  "$@"
  local exit_code=$?
  end=$(date +%s)
  elapsed=$((end - start))
  log_message "INFO" "Command '$*' completed in ${elapsed}s"
  return $exit_code
}

# Clean temporary files on exit
#   e.g. trap cleanup EXIT
cleanup() {
  log_message "INFO" "Cleaning up..."
  rm -f /tmp/my-temp-file
}

# Check if port is in use
cloud_is_port_in_use() {
  local port="$1"

  local proc pid
  proc=$(lsof -iTCP:"$port" -sTCP:LISTEN 2>/dev/null)
  pid=$(lsof -t -iTCP:"$port" -sTCP:LISTEN 2>/dev/null)

  if [[ -n "$proc" ]]; then
    log_message "ERROR" "Port $port is in use by: 'PID=$pid'"
    return 0
  else
    return 1
  fi
}