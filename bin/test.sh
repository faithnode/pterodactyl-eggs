#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ROOT="$(realpath "$(dirname "$(realpath "$0")")/..")"
DIST="$ROOT/.dist"

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed.${NC}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: docker is not installed or not running.${NC}"
    exit 1
fi

if [ ! -d "$DIST" ] || [ -z "$(ls -A "$DIST")" ]; then
    echo "Dist folder not found. Building eggs..."
    bash "$ROOT/bin/build.sh"
fi

echo "Starting tests..."

SEARCH_TERM="${1:-}"

find "$DIST" -name '*.json' -not -name 'index.json' | while read -r file; do
    if [ -n "$SEARCH_TERM" ] && [[ "$file" != *"$SEARCH_TERM"* ]]; then
        continue
    fi

    EGG_NAME=$(basename "$file" .json)
    echo -e "Testing ${GREEN}$EGG_NAME${NC}..."

    TMP_SCRIPT="$(mktemp)"
    chmod +x "$TMP_SCRIPT"

    CONTAINER=$(jq -r '.scripts.installation.container' "$file")
    ENTRYPOINT=$(jq -r '.scripts.installation.entrypoint' "$file")
    
    jq -r '.scripts.installation.script' "$file" > "$TMP_SCRIPT"

    if [ ! -s "$TMP_SCRIPT" ]; then
        echo -e "${RED}Skipping $EGG_NAME: Installation script is empty.${NC}"
        rm -f "$TMP_SCRIPT"
        continue
    fi

    echo "  Container: $CONTAINER"
    
    docker run --rm --platform linux/amd64 \
        --entrypoint "$ENTRYPOINT" \
        -v "$TMP_SCRIPT:/mnt/install/script.sh" \
        "$CONTAINER" \
        -c "chmod +x /mnt/install/script.sh && /mnt/install/script.sh"

    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}SUCCESS: $EGG_NAME passed.${NC}\n"
    else
        echo -e "${RED}FAILED: $EGG_NAME failed with exit code $EXIT_CODE.${NC}\n"
    fi

    rm -f "$TMP_SCRIPT"
done
