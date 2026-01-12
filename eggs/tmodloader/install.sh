#!/bin/bash
apt update
apt install -y curl jq file unzip

GITHUB_PACKAGE=tModLoader/tModLoader

if [ -z "" ] && [ -z "" ] ; then
    echo -e "using anon api call"
else
    echo -e "user and oauth token set"
    alias curl='curl -u $GITHUB_USER:$GITHUB_OAUTH_TOKEN '
fi

LATEST_JSON=$(curl --silent "https://api.github.com/repos/$GITHUB_PACKAGE/releases/latest")
RELEASES=$(curl --silent "https://api.github.com/repos/$GITHUB_PACKAGE/releases")

if [ -z "$VERSION" ] || [ "$VERSION" == "latest" ]; then
    echo -e "defaulting to latest release"
    DOWNLOAD_LINK=$(echo $LATEST_JSON | jq .assets | jq -r .[].browser_download_url | grep -i linux | grep -i zip)
else
    VERSION_CHECK=$(echo $RELEASES | jq -r --arg VERSION "$VERSION" '.[] | select(.tag_name==$VERSION) | .tag_name')
    if [ "$VERSION" == "$VERSION_CHECK" ]; then
        DOWNLOAD_LINK=$(echo $RELEASES | jq -r --arg VERSION "$VERSION" '.[] | select(.tag_name==$VERSION) | .assets[].browser_download_url' | grep -i linux)
    else
        echo -e "defaulting to latest release"
        DOWNLOAD_LINK=$(echo $LATEST_JSON | jq .assets | jq -r .[].browser_download_url | grep -i linux | grep -i zip)
    fi
fi

mkdir -p /mnt/server
cd /mnt/server

echo -e "running: curl -sSL ${DOWNLOAD_LINK} -o ${DOWNLOAD_LINK##*/}"
curl -sSL ${DOWNLOAD_LINK} -o ${DOWNLOAD_LINK##*/}

FILETYPE=$(file -F ',' ${DOWNLOAD_LINK##*/} | cut -d',' -f2 | cut -d' ' -f2)
if [ "$FILETYPE" == "gzip" ]; then
    tar xzvf ${DOWNLOAD_LINK##*/}
elif [ "$FILETYPE" == "Zip" ]; then
    unzip -o ${DOWNLOAD_LINK##*/}
else
    echo -e "unknown filetype. Exiting"
    exit 2
fi

chmod +x tModLoaderServer.bin.x86_64
chmod +x tModLoaderServer

echo -e "Cleaning up extra files."
rm -rf terraria-server-${CLEAN_VERSION}.zip rm ${DOWNLOAD_LINK##*/}
