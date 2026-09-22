#!/bin/bash
# Shared parsing helpers for the bash-based egg builder.
#
# Provides:
#   eggparse_expand_imports <file>       -> prints fully source-expanded text
#   eggparse_header <file>               -> prints TSV parse events (see below)
#   eggparse_startup_sh <file>           -> prints the reduced one-line startup command
#   eggparse_load_json <file>            -> prints file content as JSON (yq for yml/yaml, cat for json)
#
# This file is meant to be `source`d, not executed directly.

set -eo pipefail

# --- import expansion -------------------------------------------------------
#
# Recursively replaces build-time imports with the raw content of the
# referenced file. Only a strict, unambiguous form is treated as a build-time
# import: a line consisting of exactly "source <relative/path>" - no leading
# indentation, no quotes, no variable expansion, nothing else on the line.
# This is deliberately real bash syntax (not a magic comment), so an
# install.sh can also be run directly - `cd <egg_dir> && bash install.sh` -
# and behave correctly without going through this build pipeline at all.
#
# Any other use of "source" or its "." alias (indented, quoted, with extra
# arguments, using "." instead of "source", etc.) is a hard build error.
# Such usages are ambiguous - they could be a "flatten me at build time"
# import or genuine runtime sourcing the author wants preserved verbatim -
# and silently leaving them unexpanded would produce a script that's broken
# at install time (the referenced repo file won't exist inside the install
# container). The author must resolve the ambiguity explicitly.
#
# Heredoc-aware: lines inside a heredoc body (<<EOF, <<-EOF, <<'EOF', ...)
# are never treated as import directives, since heredoc content is literal
# output - not shell syntax - and may coincidentally contain a line that
# looks like "source foo.sh".
#
# Cycle-safe: aborts with an error if a file tries to (transitively) source
# itself.
eggparse_expand_imports() {
  local file="$1"
  shift || true
  local abs_file
  abs_file="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"

  local frame
  for frame in "$@"; do
    if [[ "$frame" == "$abs_file" ]]; then
      echo "ERROR: source cycle detected involving $abs_file" >&2
      return 1
    fi
  done

  local dir
  dir="$(dirname "$abs_file")"

  local line heredoc_end="" strip_tabs=false trimmed rel target
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -n "$heredoc_end" ]]; then
      printf '%s\n' "$line"
      trimmed="$line"
      if $strip_tabs; then
        while [[ "$trimmed" == $'\t'* ]]; do trimmed="${trimmed#$'\t'}"; done
      fi
      [[ "$trimmed" == "$heredoc_end" ]] && heredoc_end=""
      continue
    fi

    if [[ $line =~ ^source[[:space:]]+([^[:space:]\'\"\$]+)[[:space:]]*$ ]]; then
      rel="${BASH_REMATCH[1]}"
      target="$dir/$rel"
      if [[ ! -f "$target" ]]; then
        echo "ERROR: source target not found: $target (sourced from $abs_file)" >&2
        return 1
      fi
      local inlined
      inlined="$(eggparse_expand_imports "$target" "$abs_file" "$@")" || return 1
      # A sourced library file conventionally carries its own "#!" shebang
      # line purely for editor/shellcheck purposes - it is never actually
      # executed as an entrypoint (the file is source'd, not run). Drop that
      # line so it doesn't leak into the inlined output as a stray comment.
      [[ "$inlined" == '#!'* ]] && inlined="${inlined#*$'\n'}"
      printf '%s\n' "$inlined"
      continue
    fi

    if [[ $line =~ ^[[:space:]]*(source|\.)([[:space:]]|$) ]]; then
      echo "ERROR: ambiguous/unsupported source usage (only unindented, unquoted 'source <relative/path>' with nothing else on the line is supported): $line" >&2
      return 1
    fi

    if [[ $line =~ \<\<(-?)[[:space:]]*[\"\']?([A-Za-z_][A-Za-z0-9_]*) ]]; then
      heredoc_end="${BASH_REMATCH[2]}"
      [[ "${BASH_REMATCH[1]}" == "-" ]] && strip_tabs=true || strip_tabs=false
    fi

    printf '%s\n' "$line"
  done < "$abs_file"
}

# --- install.sh header parsing ----------------------------------------------
#
# Reads already source-expanded install.sh content and emits one TSV event
# per line to stdout:
#   ENTRYPOINT\t<value>    first line, if it is a shebang (#!...)
#   IMAGE\t<value>          from "# @image <value>"
#   HEADER_END\t<line_number>   1-indexed line at which the script body
#                                  begins (first non-comment or blank line)
#
# Rules:
#  - A plain "#" comment or any other comment line that does not look like a
#    directive is silently dropped (does not end the header).
#  - Any "# @<name> ..." line where <name> isn't a known directive (image) is
#    a hard error - this catches stale/typo'd directives instead of silently
#    ignoring them.
#  - The header ends at the first line that is blank or does not start with
#    "#"; everything from that line to EOF is the verbatim script body.
#
# Variable declarations are not part of this format; they live in
# eggs/<nest>/<egg>/variables/<ENV_VAR>.{json,yml,yaml} files instead (see
# collect_dir_vars in bin/build.sh).
eggparse_header() {
  local file="$1"
  local line_no=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))

    if [[ $line_no -eq 1 && $line =~ ^#! ]]; then
      printf 'ENTRYPOINT\t%s\n' "${line#\#!}"
      continue
    fi

    if [[ -z "$line" || ! $line =~ ^# ]]; then
      printf 'HEADER_END\t%s\n' "$line_no"
      return 0
    fi

    if [[ $line =~ ^#[[:space:]]*@image([[:space:]]+(.*))?$ ]]; then
      printf 'IMAGE\t%s\n' "${BASH_REMATCH[2]}"
      continue
    fi

    if [[ $line =~ ^#[[:space:]]*@ ]]; then
      echo "ERROR: unknown directive (line $line_no of $file): $line" >&2
      return 1
    fi

    # ordinary comment - silently dropped, header continues
  done < "$file"

  # EOF reached while still inside the header (file is only comments)
  printf 'HEADER_END\t%s\n' "$((line_no + 1))"
  return 0
}

# --- startup.sh reduction ----------------------------------------------------
#
# Strips the shebang and comments, trims whitespace, drops line-continuation
# backslashes and joins everything into a single-line startup command.
eggparse_startup_sh() {
  local file="$1"
  local out="" line stripped

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ $line =~ ^#! ]] && continue
    [[ $line =~ ^[[:space:]]*#.*$ ]] && continue
    [[ $line =~ ^[[:space:]]*$ ]] && continue

    stripped="${line%\\}"
    stripped="$(printf '%s' "$stripped" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [[ -z "$stripped" ]] && continue

    if [[ -n "$out" ]]; then
      out="$out $stripped"
    else
      out="$stripped"
    fi
  done < "$file"

  printf '%s' "$out"
}

# --- comment stripping --------------------------------------------------------
#
# Reads a shell script on stdin and prints it back with full-line "# ..."
# comments removed (leading whitespace before the "#" is allowed).
#
# Heredoc-aware: while inside a heredoc body (<<EOF, <<-EOF, <<'EOF',
# <<"EOF", ...) lines are passed through verbatim and never treated as
# comments, since heredoc content is literal output - not shell syntax - and
# may itself contain lines starting with "#" (e.g. a nested script's own
# shebang). "<<-" heredocs may have their terminator indented with tabs;
# that indentation is accounted for when looking for the closing line.
#
# Deliberately conservative: only whole-line comments are removed. Trailing
# "cmd # comment" comments are left untouched, and so is "#" used inside
# parameter expansions (${var#pattern}, ${var##pattern}) or quoted strings -
# reliably telling those apart from a real comment requires a full shell
# tokenizer, which a regex-based line scanner cannot safely provide.
eggparse_strip_comments() {
  local line trimmed
  local heredoc_end="" strip_tabs=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -n "$heredoc_end" ]]; then
      printf '%s\n' "$line"
      trimmed="$line"
      if $strip_tabs; then
        while [[ "$trimmed" == $'\t'* ]]; do trimmed="${trimmed#$'\t'}"; done
      fi
      [[ "$trimmed" == "$heredoc_end" ]] && heredoc_end=""
      continue
    fi

    [[ $line =~ ^[[:space:]]*#.*$ ]] && continue

    if [[ $line =~ \<\<(-?)[[:space:]]*[\"\']?([A-Za-z_][A-Za-z0-9_]*) ]]; then
      heredoc_end="${BASH_REMATCH[2]}"
      [[ "${BASH_REMATCH[1]}" == "-" ]] && strip_tabs=true || strip_tabs=false
    fi

    printf '%s\n' "$line"
  done
}

# --- YAML/JSON loading --------------------------------------------------------
#
# Prints the content of a .json/.yml/.yaml file as JSON on stdout.
eggparse_load_json() {
  local file="$1"
  case "$file" in
    *.json)
      cat "$file"
      ;;
    *.yml|*.yaml)
      yq -o=json '.' "$file"
      ;;
    *)
      echo "ERROR: unsupported file extension: $file" >&2
      return 1
      ;;
  esac
}
