apt update
apt -y install curl tar git wget

cd /mnt/server

echo "Downloading rage.mp"
curl -sSL -o linux_x64.tar.gz https://cdn.rage.mp/updater/prerelease/server-files/linux_x64.tar.gz

tar -xzvf linux_x64.tar.gz --strip 1 -C /mnt/server

rm linux_x64.tar.gz

chmod +x ./ragemp-server

if [ -e conf.json ]; then
    echo "server config file exists"
else
    echo "Downloading default rage.mp config"
    curl https://raw.githubusercontent.com/parkervcp/eggs/master/game_eggs/gta/ragemp/conf.json >> conf.json
fi

echo "install complete"
exit 0
