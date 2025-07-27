#!/bin/bash

apt install -y curl jq

if [[ -z $_INSTALL_PAPER_VERSION || ${_INSTALL_PAPER_VERSION,,} == "latest" ]]; then
  echo -e "Getting latest version";
  _INSTALL_PAPER_VERSION=$(curl -s https://api.papermc.io/v2/projects/paper | jq -r '.versions[-1]');
else
  if [[ -z $(curl -s https://api.papermc.io/v2/projects/paper | jq -r ".versions[] | select(. == \"${_INSTALL_PAPER_VERSION}\")") ]]; then
    echo "Version $_INSTALL_PAPER_VERSION not found";
    exit 1;
  fi
fi

echo -e "Getting latest build"
PAPER_LAST_BUILD=$(curl -s https://api.papermc.io/v2/projects/paper/versions/${_INSTALL_PAPER_VERSION} | jq -r '.builds[-1]')

echo -e "Getting download link"
DOWNLOAD_LINK=https://api.papermc.io/v2/projects/paper/versions/${_INSTALL_PAPER_VERSION}/builds/${PAPER_LAST_BUILD}/downloads/paper-${_INSTALL_PAPER_VERSION}-${PAPER_LAST_BUILD}.jar

if [ -e ./paper*.jar ]; then
  echo -e "Removing old jars"
  rm -r ./paper*.jar || true
fi

echo -e "Downloading ${DOWNLOAD_LINK}"
curl ${DOWNLOAD_LINK} -o paper-${_INSTALL_PAPER_VERSION}-${PAPER_LAST_BUILD}.jar

echo -e "Agree eula";
echo "eula=true" > "eula.txt";

echo -e "Install complete"