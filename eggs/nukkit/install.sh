#!/bin/ash

apk add --no-cache curl openssl

cd /mnt/server

if [ ! -z "" ]; then
    MODIFIED_DOWNLOAD=`eval echo $(echo "" | sed -e 's/{{/${/g' -e 's/}}/}/g')`
    wget ${MODIFIED_DOWNLOAD} -O ${SERVER_JARFILE}
elif [ -z "${NUKKIT_VERSION}" ] || [ "${NUKKIT_VERSION}" == "latest" ]; then
    wget https://ci.opencollab.dev/job/NukkitX/job/Nukkit/job/master/lastSuccessfulBuild/artifact/target/nukkit-1.0-SNAPSHOT.jar -O ${SERVER_JARFILE}
else
    wget https://ci.opencollab.dev/job/NukkitX/job/Nukkit/job/master/${NUKKIT_VERSION}/artifact/target/nukkit-1.0-SNAPSHOT.jar -O ${SERVER_JARFILE}
fi

if [ ! -f nukkit.yml ]; then
    wget https://raw.githubusercontent.com/parkervcp/eggs/master/game_eggs/minecraft/bedrock/nukkit/nukkit.yml
fi

if [ ! -f server.properties ]; then
    wget https://raw.githubusercontent.com/parkervcp/eggs/master/game_eggs/minecraft/bedrock/nukkit/server.properties
fi
