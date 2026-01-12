#!/bin/bash

apt-get update
apt-get install -y git curl wget jq file tar unzip zip

mkdir -p /mnt/server/

cd /mnt/server || exit 1

ARCH=$([[ "$(uname -m)" == "x86_64" ]] && printf "amd64" || printf "arm64")

VERSION="${VERSION:-PM5}"
VERSION="${VERSION^^}"

download_php_binary() {
  curl --location --progress-bar https://github.com/pmmp/PHP-Binaries/releases/download/"${VERSION,,}"-php-"$REQUIRED_PHP_VERSION"-latest/PHP-"$REQUIRED_PHP_VERSION"-Linux-x86_64-"$VERSION".tar.gz | tar -xzv
  curl --location --progress-bar https://github.com/pmmp/PHP-Binaries/releases/download/php-"$REQUIRED_PHP_VERSION"-latest/PHP-Linux-x86_64-"$VERSION".tar.gz | tar -xzv
}

set_php_extension_dir() {
  EXTENSION_DIR=$(find "bin" -name '*debug-zts*')
  grep -q '^extension_dir' bin/php7/bin/php.ini && sed -i'bak' "s{^extension_dir=.*{extension_dir=\"$EXTENSION_DIR\"{" bin/php7/bin/php.ini || echo "extension_dir=\"$EXTENSION_DIR\"" >>bin/php7/bin/php.ini
}

download_pmmp() {
  DOWNLOAD_LINK=$(curl -sSL https://update.pmmp.io/api?channel="$API_CHANNEL" | jq -r '.download_url')
  curl --location --progress-bar "${DOWNLOAD_LINK}" --output PocketMine-MP.phar
}

if [[ "${VERSION}" == "PM4" ]]; then
  API_CHANNEL="4"

elif [[ "${VERSION}" == "PM5" ]]; then
   API_CHANNEL="stable"
else
  exit 1
fi

REQUIRED_PHP_VERSION=$(curl -sSL https://update.pmmp.io/api?channel="$API_CHANNEL" | jq -r '.php_version')

if [[ "${ARCH}" == "amd64" ]]; then
  download_php_binary

else
  apt install -y make autoconf automake m4 bzip2 bison g++ cmake pkg-config re2c libtool-bin
  
  mkdir -p /mnt/server/build_cache/archives
  mkdir -p /mnt/server/build_cache/compilation
  
  curl --location --progress-bar --remote-name https://raw.githubusercontent.com/pmmp/PHP-Binaries/php/"$REQUIRED_PHP_VERSION"/compile.sh
  chmod +x compile.sh

  THREADS=$(grep -c ^processor /proc/cpuinfo) || THREADS=1
  ./compile.sh -j "${THREADS}" -c /mnt/server/build_cache/archives -l /mnt/server/build_cache/compilation -P ${VERSION:2}
  rm compile.sh
  rm -rf install_data/

fi

download_pmmp
set_php_extension_dir || exit 1

if [[ ! -f server.properties ]]; then
  curl --location --progress-bar --remote-name https://raw.githubusercontent.com/parkervcp/eggs/master/game_eggs/minecraft/bedrock/pocketmine_mp/server.properties
fi

touch banned-ips.txt banned-players.txt ops.txt white-list.txt server.log
mkdir -p players worlds plugins resource_packs
