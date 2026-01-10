#!/bin/bash

set -euo pipefail

URL="${URL:-}"
COMMENT="${COMMENT:-}"
AUTHOR="${AUTHOR:-admin@faithnode.com}"
ROOT="$(realpath "$(dirname "$(realpath "$0")")/..")"
VARIABLES="$ROOT/variables.yml"
TRANSLATION="$ROOT/translation.yml"

PAGES='[]'

mkdir -p "$ROOT/.dist"

while IFS= read -r -d '' file
do
  EGG_DIR="$(dirname "$file")"
  URL_PATH="$(realpath --relative-base "$ROOT/eggs" "$EGG_DIR")"
  OUT_DIR="$ROOT/.dist/$URL_PATH";
  OUT_NAME="$(basename "$EGG_DIR").json"

  mkdir -p "${OUT_DIR}";

  CONFIG="$(
    yq -o=json eval "$(printf '
      (.. |
        with(select(tag == "!!var");
          . |= (. | to_string | split(".") | .[] as $item ireduce (load("%s"); .[$item]))
        ) |
        with(select(tag == "!!in");
          . |= (. | to_string | split(".") | .[] as $item ireduce (load("%s"); .[$item]))
        ) |
        with(select(tag == "!!file");
          . |= (
            if (. | test("^/"))
            then load_str("%s" + .)
            else load_str("%s/" + .)
            end
          )
        )
      )
    ' "$VARIABLES" "$TRANSLATION" "$ROOT" "$EGG_DIR")" \
      "$EGG_DIR/egg.yml"
  )"

  UPDATE_URL=""
  if [ -n "$URL" ]; then
    UPDATE_URL="${URL%/}/$URL_PATH/$OUT_NAME"
    PAGES="$(echo "$PAGES" | jq "$(printf '. += ["%s"]' "$UPDATE_URL")")"
  fi


  echo "$CONFIG" | jq \
  "$(
    printf '
      def nullable: if . == "" or . == "null" or . == null then null else . end;
      def default($default): if (. | nullable) == null then $default else . end;

      {
        _comment: ("%s" | nullable),
        meta: {
          version: "PTDL_v2",
          update_url: ("%s" | nullable)
        },
        exported_at: "%s",
        name: (.name // "" | tostring),
        description: (.description | tostring | nullable),
        author: ("%s" | default("admin@faithnode.com")),
        features: (.features // []),
        docker_images: (
          (.images // []) | map(
            .name as $name |
            .image as $image |
            (.tags // [null])[] as $tag | {
              name: (.name | sub("{tag}"; $tag | tostring)),
              image: (.image | sub("{tag}"; $tag | tostring))
            }) | reduce .[] as $i ({}; .[$i.name] = $i.image)
        ),
        file_denylist: (.config.denylist // []),
        startup: (.config.cmd // "echo \\"Hello world\\""),
        config: {
          files: (.config.files // {} | tostring),
          startup: (.config.startup // {"done":""} | tostring),
          logs: (.config.logs // {} | tostring),
          stop: (.config.stop // "^c" | tostring),
        },
        scripts: {
          installation: (
            (.install.container // "debian:bookworm-slim") as $container |
            (.install.entrypoint // "/bin/bash") as $entrypoint |
            (
              .install.script
              | if . == null then []
                elif type == "string" then [ . ]
                elif type == "array" then .
                else []
                end
            ) as $scriptParts |
            {
              script: ($scriptParts | join("\n\n")),
              container: $container,
              entrypoint: $entrypoint
            }
          )
        },
        variables: (
          (.variables // []) | map({
            name: (.name | tostring),
            description: (.description | tostring),
            env_variable: (.env | tostring),
            default_value: (.value | tostring),
            user_viewable: (.permissions.view // true | tostring | test("true")),
            user_editable: (.permissions.edit // true | tostring | test("true")),
            rules: (.rules // "string" | tostring),
            field_type: (.type // "text" | tostring)
          })
        ),
      }
    ' \
    "$COMMENT" \
    "$UPDATE_URL" \
    "$(date '+%Y-%m-%dT%H:%M:%S%:z')" \
    "$AUTHOR"
  )" > "${OUT_DIR}/${OUT_NAME}";
done < <(find "$ROOT/eggs" -name 'egg.yml' -print0);

echo '
---
permalink: /index.json
---
' > "$ROOT/.dist/404.md";

echo "$PAGES" | jq > "$ROOT/.dist/index.json";
