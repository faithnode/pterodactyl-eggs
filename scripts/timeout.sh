#!/bin/sh

if [ -z "${_TIMEOUT_GUARD:-}" ]; then
  if command -v timeout >/dev/null 2>&1; then
    export _TIMEOUT_GUARD=1
    chmod +x "$0";
    exec timeout -k 10 -s TERM "${TIMEOUT_SECONDS:-600}" "$0" "$@"
  fi
fi
