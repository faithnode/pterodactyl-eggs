#! /bin/bash

apt update
apt install -y curl jq file unzip

if [ ! -d /mnt/server/ ]; then
    mkdir -p /mnt/server/
fi

cd /mnt/server/

if [ -z "${GITHUB_USER}" ] && [ -z "${GITHUB_OAUTH_TOKEN}" ] ; then
    alias curl='curl '
else
    alias curl='curl -u ${GITHUB_USER}:${GITHUB_OAUTH_TOKEN} '
fi

LATEST_VERSION=$(curl -sL https://api.github.com/repos/gomint/gomint/tags | jq -r '.[-1].name')

DOWNLOAD_URL=https://github.com/gomint/gomint/releases/download/${LATEST_VERSION}/${LATEST_VERSION}.zip

if [ ! -z "${DOWNLOAD_URL}" ]; then
    if curl --output /dev/null --silent --head --fail ${DOWNLOAD_URL}; then
        VALIDATED_URL=${DOWNLOAD_URL}
    else
        exit 2
    fi
fi

curl -sSL -o ${VALIDATED_URL##*/} ${VALIDATED_URL}

FILETYPE=$(file -F ',' ${VALIDATED_URL##*/} | cut -d',' -f2 | cut -d' ' -f2)
if [ "$FILETYPE" == "gzip" ]; then
    tar xzvf ${VALIDATED_URL##*/}
elif [ "$FILETYPE" == "Zip" ]; then
    unzip ${VALIDATED_URL##*/} -d modules/
elif [ "$FILETYPE" == "XZ" ]; then
    tar xvf ${VALIDATED_URL##*/}
else
    # exit 2
    echo "unknown filetype"
fi

rm ${VALIDATED_URL##*/}
mv modules/modules/* modules
rm -rf modules/modules
rm modules/start.*

if [ ! -f server.yml ]; then
    curl -sSL -o server.yml https://raw.githubusercontent.com/parkervcp/eggs/master/game_eggs/minecraft/bedrock/gomint/server.yml
fi
