#!/bin/bash

PAPER_API_URL='https://fill.papermc.io'
PROJECT=velocity
VERSION=$_INSTALL_VELOCITY_VERSION

echo -e "Getting $PROJECT versions";
VERSIONS="$(curl "$PAPER_API_URL/v3/projects/$PROJECT" | jq -r '.versions | to_entries | map(.value) | flatten')"

if [[ -z $VERSION || ${VERSION,,} == "latest" ]]; then
  echo -e "Getting latest version";
  VERSION=$(echo "$VERSIONS" | jq -r '.[0]');
else
  if [[ -z $(echo "$VERSIONS" | jq -r "$(printf '.[] | select(. == "%s")' "$VERSION")") ]]; then
    fatal "Version $VERSION not found";
  fi
fi


echo -e "Getting $PROJECT latest build data"
BUILD_DATA="$(curl "$PAPER_API_URL/v3/projects/$PROJECT/versions/$VERSION/builds/latest" | jq -r '.downloads."server:default"')"

JARFILE="$(echo "$BUILD_DATA" | jq -r ".name")"
DOWNLOAD_URL="$(echo "$BUILD_DATA" | jq -r ".url")"

echo -e "Removing old jars";
rm -rf ./$PROJECT*.jar;

echo -e "Downloading $JARFILE"
curl "$DOWNLOAD_URL" -o "$JARFILE"

echo -e "Agree eula";
echo "eula=true" > "eula.txt";
