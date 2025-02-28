#!/bin/bash

PAPER_API_URL='https://api.papermc.io'
PROJECT=velocity
VERSION=$_INSTALL_VELOCITY_VERSION

echo -e "Getting $PROJECT versions";
VERSIONS="$(curl "$PAPER_API_URL/v2/projects/$PROJECT" | jq '.versions')"

if [[ -z $VERSION || ${VERSION,,} == "latest" ]]; then
  echo -e "Getting latest version";
  VERSION=$(echo "$VERSIONS" | jq -r '.[-1]');
else
  if [[ -z $(echo "$VERSIONS" | jq -r "$(printf '.[] | select(. == "%s")' "$VERSION")") ]]; then
    fatal "Version $VERSION not found";
  fi
fi

echo -e "Getting $PROJECT latest build"
LATEST_BUILD=$(curl "$PAPER_API_URL/v2/projects/$PROJECT/versions/$VERSION" | jq -r '.builds[-1]')

echo -e "Getting download link"
JARFILE="$PROJECT-$VERSION-$LATEST_BUILD.jar"

echo -e "Removing old jars";
rm -rf ./$PROJECT*.jar;

echo -e "Downloading $JARFILE"
curl "$PAPER_API_URL/v2/projects/$PROJECT/versions/$VERSION/builds/$LATEST_BUILD/downloads/$JARFILE" -o "$JARFILE"

echo -e "Agree eula";
echo "eula=true" > "eula.txt";
