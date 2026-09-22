#!/bin/bash
# Generates .dist/index.json (a flat list of every built egg's public URL) and
# a Jekyll-style .dist/404.md redirect stub, for panels that support
# autoupdate-by-index and for GitHub Pages hosting respectively.
#
# Run after bin/build.sh. Env vars:
#   URL - base URL the built eggs are published under
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DIST_DIR="$REPO_ROOT/.dist"
URL="${URL:-https://pterodactyl-eggs.faithnode.com/}"
[[ "$URL" != */ ]] && URL="$URL/"

fatal() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ -d "$DIST_DIR" ]] || fatal "$DIST_DIR does not exist - run bin/build.sh first"

urls_json="[]"
while IFS= read -r f; do
  rel="${f#"$DIST_DIR"/}"
  url="${URL}${rel}"
  urls_json="$(jq --arg u "$url" '. + [$u]' <<<"$urls_json")"
done < <(find "$DIST_DIR" -name '*.json' ! -name 'index.json' | sort)

jq -S '. | sort' <<<"$urls_json" > "$DIST_DIR/index.json"
echo "Wrote ${DIST_DIR#"$REPO_ROOT"/}/index.json ($(jq 'length' "$DIST_DIR/index.json") eggs)" >&2

cat > "$DIST_DIR/404.md" <<EOF
---
permalink: /404.html
layout: default
---

# 404 - Not Found
EOF
echo "Wrote ${DIST_DIR#"$REPO_ROOT"/}/404.md" >&2
