#!/bin/bash

# ===  INIT  ===
set -eo pipefail;
mkdir -p /mnt/server/ && cd /mnt/server/;
apt update && apt install -y curl jq;

# === HELPERS ===
function fatal() {
  echo "$@";
  exit 1;
}

function curl() {
  /usr/bin/curl -sf -L --show-error "$@";
}

# === GLOBAL TIMEOUT ===
MAIN_PID=$$
(
  sleep 600
  echo "Global timeout exeeded..."
  kill -9 $MAIN_PID 2>/dev/null
) &
TIMER_PID=$!

# === EXIT TRAP ===
function before_exit() {
  kill $TIMER_PID 2>/dev/null

  if [ $? == 0 ]; then
      echo -e "Install complete"
  else
    echo -e "Install failed"
  fi
}
trap before_exit EXIT
