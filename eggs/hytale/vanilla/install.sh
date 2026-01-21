#!/bin/bash

DOWNLOADER_FILE="hytale-downloader.zip"
DOWNLOADER_URL="https://downloader.hytale.com/${DOWNLOADER_FILE}"
DONLOADER_DIR=./downloader

apt install -y unzip;

curl "${DOWNLOADER_URL}" -o "/tmp/${DOWNLOADER_FILE}";

rm -rf "${DONLOADER_DIR}";
mkdir -p "${DONLOADER_DIR}";

unzip "/tmp/${DOWNLOADER_FILE}" -d "${DONLOADER_DIR}" 'hytale-downloader-linux-amd64'
chmod +x "${DONLOADER_DIR}/hytale-downloader-linux-amd64"

cat <<EOL > start.sh
#!/bin/sh
if [ ! -f "Server/HytaleServer.jar" ]; then
    ${DONLOADER_DIR}/hytale-downloader-linux-amd64 && unzip -o [0-9]*.[0-9]*.[0-9]*-*.zip;
fi

java -Xms128M -XX:MaxRAMPercentage=80 -jar Server/HytaleServer.jar --auth-mode authenticated --assets Assets.zip --bind "0.0.0.0:${SERVER_PORT}";

EOL

chmod +x ./start.sh