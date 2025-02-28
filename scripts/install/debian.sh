#!/bin/bash

# ===  INIT  ===
set -eo pipefail;
mkdir -p /mnt/server/ && cd /mnt/server/;
apt update && apt install -y curl jq;

function fatal() {
  echo "$@";
  exit 1;
}

function curl() {
  /usr/bin/curl -sf -L --show-error "$@";
}

function before_exit() {
  if [ $? == 0 ]; then
      echo -e "Install complete"
  else
    echo -e "Install failed"
  fi
}
trap before_exit EXIT