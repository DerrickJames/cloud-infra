#!/usr/bin/env bash
set -euo pipefail

##############################################
# ANSI Color Codes and Color Printing Helpers
##############################################

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
BOLD="\033[1m"
RESET="\033[0m"

info() {
  echo -e "${CYAN}${1}${RESET}"
}

success() {
  echo -e "${GREEN}${1}${RESET}"
}

warning() {
  echo -e "${YELLOW}${1}${RESET}"
}

error() {
  echo -e "${RED}${1}${RESET}"
}

header() {
  echo -e "${BOLD}${MAGENTA}${1}${RESET}"
}