#!/bin/bash
# Static checks (+ optional real Docker install test) for every built egg.
#
# Usage: bin/test.sh [filter]
#   filter - only test eggs whose dist path contains this substring
#
# Env vars:
#   DOCKER_TEST=0   - force-skip the real Docker install test even if docker
#                      is available (default: run it when docker is usable)
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DIST_DIR="$REPO_ROOT/.dist"
FILTER="${1:-}"
FAILED=0

fatal() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ -d "$DIST_DIR" ]] || fatal "$DIST_DIR does not exist - run bin/build.sh first"

docker_usable=0
if [[ "${DOCKER_TEST:-1}" != "0" ]] && command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  docker_usable=1
fi

check_egg() {
  local file="$1"
  local rel="${file#"$DIST_DIR"/}"
  local ok=1

  echo "== $rel =="

  local egg
  egg="$(cat "$file")"

  local name startup script container entrypoint
  name="$(jq -r '.name // empty' <<<"$egg")"
  startup="$(jq -r '.startup // empty' <<<"$egg")"
  script="$(jq -r '.scripts.installation.script // empty' <<<"$egg")"
  container="$(jq -r '.scripts.installation.container // empty' <<<"$egg")"
  entrypoint="$(jq -r '.scripts.installation.entrypoint // empty' <<<"$egg")"

  [[ -z "$name" ]] && { echo "  FAIL: missing 'name'"; ok=0; }
  [[ -z "$startup" ]] && { echo "  FAIL: missing 'startup'"; ok=0; }
  [[ -z "$container" ]] && { echo "  FAIL: missing 'scripts.installation.container'"; ok=0; }
  [[ -z "$entrypoint" ]] && { echo "  FAIL: missing 'scripts.installation.entrypoint'"; ok=0; }

  if [[ -n "$script" ]]; then
    local tmp
    tmp="$(mktemp)"
    printf '%s\n' "$script" > "$tmp"
    if ! bash -n "$tmp" 2>"$tmp.err"; then
      echo "  FAIL: script fails 'bash -n':"
      sed 's/^/    /' "$tmp.err"
      ok=0
    fi
    rm -f "$tmp" "$tmp.err"
  fi

  # every $_FOO / ${_FOO} / {{_FOO}} referenced in startup/script must be a
  # declared variable
  local declared_vars referenced_vars
  declared_vars="$(jq -r '[.variables[].env_variable] | join(",")' <<<"$egg")"
  referenced_vars="$( { printf '%s\n%s' "$startup" "$script"; } \
    | grep -oE '\{\{_[A-Za-z0-9_]+\}\}|\$\{_[A-Za-z0-9_]+\}|\$_[A-Za-z0-9_]+' \
    | sed -E 's/^\{\{(_[A-Za-z0-9_]+)\}\}$/\1/; s/^\$\{(_[A-Za-z0-9_]+)\}$/\1/; s/^\$(_[A-Za-z0-9_]+)$/\1/' \
    | sort -u || true)"

  local v
  for v in $referenced_vars; do
    if [[ ",$declared_vars," != *",$v,"* ]]; then
      echo "  FAIL: variable $v is referenced but not declared in 'variables'"
      ok=0
    fi
  done

  if [[ $ok -eq 1 ]]; then
    echo "  OK (static)"
  else
    FAILED=1
  fi

  if [[ $docker_usable -eq 1 && $ok -eq 1 ]]; then
    docker_install_test "$rel" "$egg" "$container" "$entrypoint" "$script"
  fi
}

docker_install_test() {
  local rel="$1" egg="$2" container="$3" entrypoint="$4" script="$5"

  local env_args=()
  local kv
  while IFS= read -r kv; do
    [[ -z "$kv" ]] && continue
    env_args+=(-e "$kv")
  done < <(jq -r '.variables[] | "\(.env_variable)=\(.default_value)"' <<<"$egg")

  local workdir
  workdir="$(mktemp -d)"
  local script_file="$workdir/install.sh"
  printf '%s\n' "$script" > "$script_file"
  chmod 777 "$script_file"

  echo "  Running Docker install test ($container)..."

  local cid
  if ! cid="$(docker create \
    -w /mnt/server \
    "${env_args[@]}" \
    --entrypoint "$entrypoint" \
    "$container" /install.sh 2>"$workdir/output.log")"; then
    echo "  FAIL: docker install test failed for $rel, output:"
    sed 's/^/    /' "$workdir/output.log"
    FAILED=1
    rm -rf "$workdir"
    return
  fi

  if ! docker cp "$script_file" "$cid:/install.sh" >"$workdir/output.log" 2>&1; then
    echo "  FAIL: docker install test failed for $rel, output:"
    sed 's/^/    /' "$workdir/output.log"
    FAILED=1
    docker rm -f "$cid" >/dev/null 2>&1 || true
    rm -rf "$workdir"
    return
  fi

  if docker start -a "$cid" > "$workdir/output.log" 2>&1; then
    echo "  OK (docker install)"
  else
    echo "  FAIL: docker install test failed for $rel, output:"
    sed 's/^/    /' "$workdir/output.log"
    FAILED=1
  fi

  docker rm -f "$cid" >/dev/null 2>&1 || true
  rm -rf "$workdir"
}

main() {
  local files=()
  while IFS= read -r f; do
    files+=("$f")
  done < <(find "$DIST_DIR" -name '*.json' ! -name 'index.json' | sort)

  [[ ${#files[@]} -eq 0 ]] && fatal "no built eggs found in $DIST_DIR - run bin/build.sh first"

  if [[ $docker_usable -eq 1 ]]; then
    echo "Docker is available - real install tests will be run." >&2
  else
    echo "Docker is not available - only static checks will be run." >&2
  fi

  local f
  for f in "${files[@]}"; do
    [[ -n "$FILTER" && "$f" != *"$FILTER"* ]] && continue
    check_egg "$f"
  done

  if [[ $FAILED -eq 1 ]]; then
    echo "Some checks FAILED." >&2
    exit 1
  fi
  echo "All checks passed." >&2
}

main "$@"
