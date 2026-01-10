#!/bin/bash

ROOT="$(realpath "$(dirname "$(realpath "$0")")/..")"
DIST="$ROOT/.dist"

if [ -z "$URL" ]; then
  echo "URL environment variable is not set."
  exit 1
fi

echo '
---
permalink: /index.json
---
' > "$DIST/404.md"

cd "$DIST" || exit
find . -type f -name "*.json" -not -name "index.json" | \
sed 's|^\./||' | \
jq -R -s --arg url "${URL%/}/" 'split("\n") | map(select(length > 0) | $url + .)' > index.json

echo "Index generated at $DIST/index.json"
