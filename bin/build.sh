#!/bin/bash

ROOT="$(realpath "$(dirname "$(realpath "$0")")/..")"
VARIABLES="$ROOT/variables.yml"
TRANSLATION="$ROOT/translation.yml"

while IFS= read -r -d '' file
do
  EGG_DIR=$(dirname "$file");
  URL_PATH=$(dirname "$(realpath --relative-base "$ROOT/eggs" "$EGG_DIR")");
  OUT_DIR="$ROOT/.dist/$URL_PATH";
  OUT_NAME=$(basename "$EGG_DIR.json");

  mkdir -p "${OUT_DIR}";

  CONFIG=$(< "${EGG_DIR}/egg.yml" yq -o=json "$(
    printf '
      (.. |
      with(select(tag == "!!var");
      . |= (. | to_string | split(".") | .[] as $item ireduce (load("%s"); .[$item]))
      ) |
      with(select(tag == "!!in");
      . |= (. | to_string | split(".") | .[] as $item ireduce (load("%s"); .[$item]))
      ) |
      with(select(tag == "!!file");
      . |= load_str("%s/" + .)
      )) |= .
      ' \
      "$VARIABLES" \
      "$TRANSLATION" \
      "$EGG_DIR"
    )
  ");