#!/bin/bash
# Builds every eggs/<nest>/<egg>/ directory into a PTDL_v2 JSON file under
# .dist/<nest>/<egg>.json, following the field-resolution rules described in
# refactoring.md / readme.md.
#
# Env vars:
#   URL     - base URL the built eggs are published under (for meta.update_url)
#   AUTHOR  - author field baked into every egg
#   COMMENT - _comment field baked into every egg
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib/eggparse.sh
source "$SCRIPT_DIR/lib/eggparse.sh"

DIST_DIR="$REPO_ROOT/.dist"
URL="${URL:-https://pterodactyl-eggs.faithnode.com/}"
[[ "$URL" != */ ]] && URL="$URL/"
AUTHOR="${AUTHOR:-admin@faithnode.com}"
COMMENT="${COMMENT:-GENERATED WITH FAITHNODE}"
EXPORTED_AT="$(date -u +%Y-%m-%dT%H:%M:%S+00:00)"

fatal() {
  echo "ERROR: $*" >&2
  exit 1
}

# --- install.sh parse result (populated by parse_install_sh) ---------------
PARSED_ENTRYPOINT=""
PARSED_IMAGE=""
PARSED_SCRIPT=""

parse_install_sh() {
  local install_file="$1"
  PARSED_ENTRYPOINT=""
  PARSED_IMAGE=""
  PARSED_SCRIPT=""

  [[ -f "$install_file" ]] || return 0

  local expanded_file events_file
  expanded_file="$(mktemp)"
  events_file="$(mktemp)"

  eggparse_expand_imports "$install_file" > "$expanded_file" \
    || fatal "failed to expand source directives in $install_file"

  if ! eggparse_header "$expanded_file" > "$events_file"; then
    rm -f "$expanded_file" "$events_file"
    fatal "failed to parse install.sh header in $install_file"
  fi

  local header_end="" tag a
  while IFS=$'\t' read -r tag a; do
    case "$tag" in
      ENTRYPOINT) PARSED_ENTRYPOINT="$a" ;;
      IMAGE) PARSED_IMAGE="$a" ;;
      HEADER_END) header_end="$a" ;;
    esac
  done < "$events_file"

  if [[ -n "$header_end" ]]; then
    PARSED_SCRIPT="$(tail -n +"$header_end" "$expanded_file")"
  fi

  rm -f "$expanded_file" "$events_file"
}

# find eggs/<nest>/<egg>/egg.{json,yml,yaml} - exactly one must exist
find_egg_body() {
  local dir="$1" candidates=()
  local ext
  for ext in json yml yaml; do
    [[ -f "$dir/egg.$ext" ]] && candidates+=("$dir/egg.$ext")
  done
  if [[ ${#candidates[@]} -eq 0 ]]; then
    fatal "no egg.json/egg.yml/egg.yaml found in $dir"
  fi
  if [[ ${#candidates[@]} -gt 1 ]]; then
    fatal "multiple egg body files found in $dir: ${candidates[*]}"
  fi
  printf '%s' "${candidates[0]}"
}

# find eggs/<nest>/<egg>/config/<name>.{json,yml,yaml}
find_config_file() {
  local dir="$1" name="$2" ext
  for ext in json yml yaml; do
    if [[ -f "$dir/config/$name.$ext" ]]; then
      printf '%s' "$dir/config/$name.$ext"
      return 0
    fi
  done
  return 1
}

# eggs/<nest>/<egg>/variables/<ENV_VAR>.{json,yml,yaml} - one file per
# variable, as an alternative to the inline egg.yml "variables:" list. The
# filename (without extension) is the env_variable name; the file body holds
# the same fields as an inline variable entry (name, description,
# default_value, user_viewable, user_editable, rules, field_type), all
# optional with sane defaults.
collect_dir_vars() {
  local egg_dir="$1"
  local dir="$egg_dir/variables"
  local result="[]"

  [[ -d "$dir" ]] || { printf '%s' "$result"; return; }

  local f env raw entry
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    env="$(basename "$f")"
    env="${env%.*}"
    raw="$(eggparse_load_json "$f")" || fatal "failed to parse $f"
    entry="$(jq -c --arg env "$env" '{
      name: (.name // $env),
      description: (.description // null),
      env_variable: $env,
      default_value: (.default_value // ""),
      user_viewable: (if .user_viewable == null then true else .user_viewable end),
      user_editable: (if .user_editable == null then true else .user_editable end),
      rules: (.rules // ""),
      field_type: (.field_type // "text")
    }' <<<"$raw")"
    result="$(jq -c --argjson e "$entry" '. + [$e]' <<<"$result")"
  done < <(find -L "$dir" -maxdepth 1 -type f \( -name '*.json' -o -name '*.yml' -o -name '*.yaml' \) | sort)

  printf '%s' "$result"
}

# resolves a config.<field> value that is stored as a *string* holding
# embedded JSON (files/startup/logs). If the field is present in the egg
# body it is used verbatim (already a string). Otherwise the sibling
# config/<field>.json|yml|yaml fallback file is read, compacted and used as
# the string value. Falls back to the literal string "{}".
resolve_config_string() {
  local egg_dir="$1" body="$2" field="$3"
  local present
  present="$(jq -r ".config.$field // empty" <<<"$body")"
  if [[ -n "$present" ]]; then
    printf '%s' "$present"
    return
  fi
  local f
  if f="$(find_config_file "$egg_dir" "$field")"; then
    eggparse_load_json "$f" | jq -c '.'
    return
  fi
  printf '{}'
}

resolve_stop() {
  local egg_dir="$1" body="$2"
  local present
  present="$(jq -r '.config.stop // empty' <<<"$body")"
  if [[ -n "$present" ]]; then
    printf '%s' "$present"
    return
  fi
  if [[ -f "$egg_dir/config/stop" ]]; then
    printf '%s' "$(cat "$egg_dir/config/stop")"
    return
  fi
  # Not explicitly documented in refactoring.md (which reuses "{}" for every
  # config.* default, likely copy-pasted); "^c" is the sane Pterodactyl
  # default for a stop *command* and matches the sample egg's own value.
  printf '^c'
}

build_egg() {
  local egg_dir="$1"
  local rel_path="${egg_dir#"$REPO_ROOT"/eggs/}"
  local nest="${rel_path%%/*}"

  echo "Building $rel_path" >&2

  local body_file body
  body_file="$(find_egg_body "$egg_dir")"
  body="$(eggparse_load_json "$body_file")" || fatal "$rel_path: failed to parse $body_file"

  local name
  name="$(jq -r '.name // empty' <<<"$body")"
  [[ -z "$name" ]] && fatal "$rel_path: 'name' is required in $body_file"

  local description
  description="$(jq -c '.description // null' <<<"$body")"

  local features file_denylist
  features="$(jq -c '.features // []' <<<"$body")"
  file_denylist="$(jq -c '.file_denylist // []' <<<"$body")"

  local docker_images
  docker_images="$(jq -c '.docker_images // empty' <<<"$body")"
  if [[ -z "$docker_images" || "$docker_images" == "null" ]]; then
    local f
    if f="$(find_config_file "$egg_dir" docker_images)"; then
      docker_images="$(eggparse_load_json "$f")"
    else
      docker_images="{}"
    fi
  fi

  local cfg_files cfg_startup cfg_logs cfg_stop
  cfg_files="$(resolve_config_string "$egg_dir" "$body" files)"
  cfg_startup="$(resolve_config_string "$egg_dir" "$body" startup)"
  cfg_logs="$(resolve_config_string "$egg_dir" "$body" logs)"
  cfg_stop="$(resolve_stop "$egg_dir" "$body")"

  parse_install_sh "$egg_dir/install.sh"

  local script container entrypoint
  script="$(jq -r '.scripts.installation.script // empty' <<<"$body")"
  [[ -z "$script" ]] && script="$PARSED_SCRIPT"
  script="$(eggparse_strip_comments <<<"$script")"
  while [[ "$script" == $'\n'* ]]; do script="${script#$'\n'}"; done

  container="$(jq -r '.scripts.installation.container // empty' <<<"$body")"
  [[ -z "$container" ]] && container="${PARSED_IMAGE:-debian:bookworm-slim}"

  entrypoint="$(jq -r '.scripts.installation.entrypoint // empty' <<<"$body")"
  [[ -z "$entrypoint" ]] && entrypoint="${PARSED_ENTRYPOINT:-/bin/bash}"

  script="$(printf "#!%s\n%s" "$entrypoint" "$script")"

  local startup
  startup="$(jq -r '.startup // empty' <<<"$body")"
  if [[ -z "$startup" ]]; then
    if [[ -f "$egg_dir/startup.sh" ]]; then
      startup="$(eggparse_startup_sh "$egg_dir/startup.sh")"
    else
      fatal "$rel_path: 'startup' is required (not set in $body_file and no startup.sh present)"
    fi
  fi

  # Variables come from two sources: the inline "variables:" list in egg.yml
  # (wins on conflict) and eggs/<nest>/<egg>/variables/*.{json,yml,yaml}.
  local body_vars dir_vars variables
  body_vars="$(jq -c '.variables // []' <<<"$body")"
  dir_vars="$(collect_dir_vars "$egg_dir")"
  dir_vars="$(jq -c --argjson have "$(jq -c '[.[].env_variable]' <<<"$body_vars")" \
    '[.[] | select(.env_variable as $e | ($have | index($e)) | not)]' <<<"$dir_vars")"
  variables="$(jq -n --argjson a "$body_vars" --argjson b "$dir_vars" '$a + $b')"

  local update_url="${URL}${rel_path}.json"

  local out_file="$DIST_DIR/$rel_path.json"
  mkdir -p "$(dirname "$out_file")"

  jq -n \
    --arg comment "$COMMENT" \
    --arg version "PTDL_v2" \
    --arg update_url "$update_url" \
    --arg exported_at "$EXPORTED_AT" \
    --arg name "$name" \
    --argjson description "$description" \
    --arg author "$AUTHOR" \
    --argjson features "$features" \
    --argjson docker_images "$docker_images" \
    --argjson file_denylist "$file_denylist" \
    --arg startup "$startup" \
    --arg cfg_files "$cfg_files" \
    --arg cfg_startup "$cfg_startup" \
    --arg cfg_logs "$cfg_logs" \
    --arg cfg_stop "$cfg_stop" \
    --arg script "$script" \
    --arg container "$container" \
    --arg entrypoint "$entrypoint" \
    --argjson variables "$variables" \
    '{
      _comment: $comment,
      meta: { version: $version, update_url: $update_url },
      exported_at: $exported_at,
      name: $name,
      description: $description,
      author: $author,
      features: $features,
      docker_images: $docker_images,
      file_denylist: $file_denylist,
      startup: $startup,
      config: { files: $cfg_files, startup: $cfg_startup, logs: $cfg_logs, stop: $cfg_stop },
      scripts: { installation: { script: $script, container: $container, entrypoint: $entrypoint } },
      variables: $variables
    }' > "$out_file"

  echo "  -> ${out_file#"$REPO_ROOT"/}" >&2
}

main() {
  umask 0000

  rm -rf "$DIST_DIR"
  mkdir -p "$DIST_DIR"

  local egg_dirs=()
  while IFS= read -r d; do
    egg_dirs+=("$d")
  done < <(find "$REPO_ROOT/eggs" -mindepth 2 -maxdepth 2 -type d | sort)

  [[ ${#egg_dirs[@]} -eq 0 ]] && fatal "no eggs found under $REPO_ROOT/eggs"

  local d
  for d in "${egg_dirs[@]}"; do
    build_egg "$d"
  done

  echo "Built ${#egg_dirs[@]} egg(s) into ${DIST_DIR#"$REPO_ROOT"/}" >&2
}

main "$@"
