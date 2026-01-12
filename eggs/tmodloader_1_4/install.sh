#!/bin/bash
apt update
apt install -y file

if [ -z "$GITHUB_USER" ] && [ -z "$GITHUB_OAUTH_TOKEN" ] ; then
    echo -e "using anon api call"
else
    echo -e "user and oauth token set"
    alias curl='curl -u $GITHUB_USER:$GITHUB_OAUTH_TOKEN '
fi

LATEST_JSON=$(curl --silent "https://api.github.com/repos/tmodloader/tmodloader/releases/latest" | jq -c '.[]' | head -1)
RELEASES=$(curl --silent "https://api.github.com/repos/tmodloader/tmodloader/releases" | jq '.[]')


if [ -z "$VERSION" ] || [ "$VERSION" == "latest" ]; then
    echo -e "defaulting to latest release"
    DOWNLOAD_LINK=$(echo $LATEST_JSON | jq .assets | jq -r .[].browser_download_url | grep -i tmodloader.zip)
else
    VERSION_CHECK=$(echo $RELEASES | jq -r --arg VERSION "$VERSION" '. | select(.tag_name==$VERSION) | .tag_name')
    if [ "$VERSION" == "$VERSION_CHECK" ]; then
        if [[ "$VERSION" == v0* ]]; then
            DOWNLOAD_LINK=$(echo $RELEASES | jq -r --arg VERSION "$VERSION" '. | select(.tag_name==$VERSION) | .assets[].browser_download_url' | grep -i linux | grep -i zip)
        else
            DOWNLOAD_LINK=$(echo $RELEASES | jq -r --arg VERSION "$VERSION" '. | select(.tag_name==$VERSION) | .assets[].browser_download_url' | grep -i tmodloader.zip)
        fi
    else
        echo -e "defaulting to latest release"
        DOWNLOAD_LINK=$(echo $LATEST_JSON | jq .assets | jq -r .[].browser_download_url | grep -i tmodloader.zip)
    fi
fi

mkdir -p /mnt/server
cd /mnt/server || exit 5

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

if [[ "$VERSION" == v0* ]]; then
    chmod +x tModLoaderServer.bin.x86_64
    chmod +x tModLoaderServer
else
    echo 'dotnet tModLoader.dll -server "$@"' > tModLoaderServer
    chmod +x tModLoaderServer
fi

echo -e "Cleaning up extra files."
rm -rf terraria-server-*.zip rm ${DOWNLOAD_LINK##*/}
if [[ "$VERSION" != v0* ]]; then
    rm -rf DedicatedServerUtils LaunchUtils PlatformVariantLibs tModPorter RecentGitHubCommits.txt *.bat *.sh
fi

mv /mnt/server/serverconfig.txt /mnt/server/config.txt
sed 's/#difficulty/difficulty/' /mnt/server/config.txt > /mnt/server/serverconfig.txt
rm /mnt/server/config.txt

echo "-----------------------------------------"
echo "Installation completed..."
echo "-----------------------------------------"
