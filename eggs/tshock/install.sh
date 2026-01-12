#!/bin/bash
apt update
apt install -y curl wget jq file unzip

GITHUB_PACKAGE=Pryaxis/TShock

if [ -z "$GITHUB_USER" ] && [ -z "$GITHUB_OAUTH_TOKEN" ] ; then
    echo -e "using anon api call"
else
    echo -e "user and oauth token set"
    alias curl='curl -u $GITHUB_USER:$GITHUB_OAUTH_TOKEN '
fi

LATEST_JSON=$(curl --silent "https://api.github.com/repos/$GITHUB_PACKAGE/releases/latest")
RELEASES=$(curl --silent "https://api.github.com/repos/$GITHUB_PACKAGE/releases")

if [ -z "$TSHOCK_VERSION" ] || [ "$TSHOCK_VERSION" == "latest" ]; then
    DOWNLOAD_LINK=$(echo $LATEST_JSON | jq .assets | jq -r .[].browser_download_url)
else
    VERSION_CHECK=$(echo $RELEASES | jq -r --arg VERSION "$TSHOCK_VERSION" '.[] | select(.tag_name==$VERSION) | .tag_name')
    if [ "$TSHOCK_VERSION" == "$VERSION_CHECK" ]; then
        DOWNLOAD_LINK=$(echo $RELEASES | jq -r --arg VERSION "$TSHOCK_VERSION" '.[] | select(.tag_name==$VERSION) | .assets[].browser_download_url')
    else
        echo -e "defaulting to latest release"
        DOWNLOAD_LINK=$(echo $LATEST_JSON | jq .assets | jq -r .[].browser_download_url)
    fi
fi

mkdir -p /mnt/server
cd /mnt/server

echo -e "running: wget $DOWNLOAD_LINK"
wget $DOWNLOAD_LINK

FILETYPE=$(file -F ',' ${DOWNLOAD_LINK##*/} | cut -d',' -f2 | cut -d' ' -f2)
if [ "$FILETYPE" == "gzip" ]; then
    tar xzvf ${DOWNLOAD_LINK##*/}
elif [ "$FILETYPE" == "Zip" ]; then
    unzip -o ${DOWNLOAD_LINK##*/}
else
    echo -e "unknown filetype. Exeting"
    exit 2
fi

echo -e "install complete"
