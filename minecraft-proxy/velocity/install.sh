#!/bin/bash

if [[ -z $_INSTALL_VELOCITY_VERSION || ${_INSTALL_VELOCITY_VERSION,,} == "latest" ]]; then
  echo -e "Getting latest version";
  _INSTALL_VELOCITY_VERSION=$(curl -s https://api.papermc.io/v2/projects/velocity | jq -r '.versions[-1]');
else
  if [[ -z $(curl -s https://api.papermc.io/v2/projects/velocity | jq -r ".versions[] | select(. == \"${_INSTALL_VELOCITY_VERSION}\")") ]]; then
    echo "Version $_INSTALL_VELOCITY_VERSION not found";
    exit 1;
  fi
fi

echo -e "Getting latest build"
VELOCITY_LAST_BUILD=$(curl -s https://api.papermc.io/v2/projects/velocity/versions/${_INSTALL_VELOCITY_VERSION} | jq -r '.builds[-1]')

echo -e "Getting download link"
DOWNLOAD_LINK=https://api.papermc.io/v2/projects/velocity/versions/${_INSTALL_VELOCITY_VERSION}/builds/${VELOCITY_LAST_BUILD}/downloads/velocity-${_INSTALL_VELOCITY_VERSION}-${VELOCITY_LAST_BUILD}.jar

echo -e "Removing old jars"
rm -r ./paper*.jar || true

echo -e "Downloading ${DOWNLOAD_LINK}"
curl ${DOWNLOAD_LINK} -o velocity-${_INSTALL_VELOCITY_VERSION}-${VELOCITY_LAST_BUILD}.jar

if [[ ! -e "velocity.toml" || -z $(cat "velocity.toml") ]]; then
    echo -e "Extracting config";
    apt install -y unzip
    unzip -p "velocity-${_INSTALL_VELOCITY_VERSION}-${VELOCITY_LAST_BUILD}.jar" default-velocity.toml > velocity.toml
fi

VELOCITY_SECRET_FILE=$(cat velocity.toml | grep -e 'forwarding-secret-file' | sed -E 's/.*\"(.*)\".*/\1/');
if [[ -n $VELOCITY_SECRET_FILE && ! -e $VELOCITY_SECRET_FILE ]]; then
  echo -e "Creating $VELOCITY_SECRET_FILE";
  echo "secret" > "$VELOCITY_SECRET_FILE";
fi

echo -e "Install complete"