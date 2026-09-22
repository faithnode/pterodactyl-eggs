#!/bin/bash

PAPER_API_URL='https://fill.papermc.io'

function install_paper_project() {
  local PROJECT="$1"
  local VERSION="$2"

  log "Getting $PROJECT versions";
  local VERSIONS
  VERSIONS="$(curl "$PAPER_API_URL/v3/projects/$PROJECT" | jq -r '.versions | to_entries | map(.value) | flatten')"

  if [[ -z $VERSION || ${VERSION,,} == "latest" ]]; then
    log "Getting latest version";
    VERSION=$(echo "$VERSIONS" | jq -r '.[0]');
  else
    if [[ -z $(echo "$VERSIONS" | jq -r "$(printf '.[] | select(. == "%s")' "$VERSION")") ]]; then
      fatal "Version $VERSION not found";
    fi
  fi

  log "Getting $PROJECT latest build data"
  local BUILD_DATA
  BUILD_DATA="$(curl "$PAPER_API_URL/v3/projects/$PROJECT/versions/$VERSION/builds/latest" | jq -r '.downloads."server:default"')"

  local JARFILE DOWNLOAD_URL
  JARFILE="$(echo "$BUILD_DATA" | jq -r ".name")"
  DOWNLOAD_URL="$(echo "$BUILD_DATA" | jq -r ".url")"

  log "Removing old jars";
  rm -rf ./"$PROJECT"*.jar;

  log "Downloading $JARFILE"
  curl "$DOWNLOAD_URL" -o "$JARFILE"

  log "Agree eula";
  echo "eula=true" > "eula.txt";
}
