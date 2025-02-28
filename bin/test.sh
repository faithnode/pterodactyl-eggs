#!/bin/bash

while IFS= read -r -d '' file
do
  TMP="$(mktemp)";
  trap "rm -f $TMP" EXIT

  < "$file" jq -r '.scripts.installation.script' > "$TMP"

  CMD="$(< "$file" jq -r '.scripts.installation.container + " " + .scripts.installation.entrypoint' | xargs printf "docker run --rm --workdir / -v ${TMP}:/script.sh %s %s script.sh")";

  if ! eval "$CMD" ; then
      exit 1;
  fi
done < <(/bin/bash -c "find $(dirname "$(realpath "$0")")/../.dist -name '*.json' -not -name 'index.json' \( -name '' $(printf ' -o -path "*%s*"' "$@") \) -print0")
