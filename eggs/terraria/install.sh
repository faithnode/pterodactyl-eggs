#!/bin/bash
apt update
apt install -y curl wget file unzip

DOWNLOAD_LINK=invalid

mkdir -p /mnt/server/
cd /mnt/server/

if [ "${TERRARIA_VERSION}" == "latest" ] || [ "${TERRARIA_VERSION}" == "" ] ; then
    DOWNLOAD_LINK=$(curl -sSL https://terraria.gamepedia.com/Server#Downloads | grep '>Terraria Server ' | grep -Eoi '<a [^>]+>' | grep -Eo 'href=\"[^"]+\"' | grep -Eo '(http|https):\/\/[^"]+' | tail -1 | cut -d'?' -f1)
else
    CLEAN_VERSION=$(echo ${TERRARIA_VERSION} | sed 's/\.//g')
    echo -e "Downloading terraria server files"
    DOWNLOAD_LINK=$(curl -sSL https://terraria.gamepedia.com/Server#Downloads | grep '>Terraria Server ' | grep -Eoi '<a [^>]+>' | grep -Eo 'href=\"[^"]+\"' | grep -Eo '(http|https):\/\/[^"]+' | grep "${CLEAN_VERSION}" | cut -d'?' -f1)
fi

if [ ! -z "${DOWNLOAD_LINK}" ]; then
    if curl --output /dev/null --silent --head --fail ${DOWNLOAD_LINK}; then
        echo -e "link is valid."
    else
        echo -e "link is invalid closing out"
        exit 2
    fi
fi

CLEAN_VERSION=$(echo ${DOWNLOAD_LINK##*/} | cut -d'-' -f3 | cut -d'.' -f1)

echo -e "running 'curl -sSL ${DOWNLOAD_LINK} -o ${DOWNLOAD_LINK##*/}'"
curl -sSL ${DOWNLOAD_LINK} -o ${DOWNLOAD_LINK##*/}

echo -e "Unpacking server files"
unzip ${DOWNLOAD_LINK##*/}

echo -e ""
cp -R ${CLEAN_VERSION}/Linux/* ./
chmod +x TerrariaServer.bin.x86_64

echo -e "Cleaning up extra files."
rm -rf ${CLEAN_VERSION}

echo -e "Generating config file"
cat <<EOF > serverconfig.txt
worldpath=/home/container/saves/Worlds
worldname=default
world=/home/container/saves/Worlds/default.wld
difficulty=3
autocreate=1
port=7777
maxplayers=8
