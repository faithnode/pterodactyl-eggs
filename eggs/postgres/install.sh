#! /bin/ash
adduser -D -h /home/container container

chown -R container: /mnt/server/

mkdir -p /mnt/server/postgres_db/run/

if ! grep -q "# Custom rules" "/mnt/server/postgres_db/pg_hba.conf"; then
    echo -e "# Custom rules\nhost    all             all             0.0.0.0/0               md5" >> "/mnt/server/postgres_db/pg_hba.conf"
fi

echo -e "Done"
