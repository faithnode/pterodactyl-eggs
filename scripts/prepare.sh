#!/bin/sh

set -eu

mkdir -p /mnt/server/ && cd /mnt/server/

apt-get update -qq && \
  apt-get install -y -qq --no-install-recommends \
    curl jq ca-certificates \
  > /dev/null 2>&1

echo "" >> /mnt/server/install.log

cat > /usr/local/sbin/curl << 'EOF'
#!/bin/sh
exec /usr/bin/curl -sf -L --show-error "$@"
EOF

cat > /usr/local/sbin/log << 'EOF'
#!/bin/sh
echo "$@"
echo "[$(date "+%Y-%m-%d %H:%M:%S")] $@" >> /mnt/server/install.log
EOF

cat > /usr/local/sbin/fatal << 'EOF'
#!/bin/sh
log "$@"
exit 1
EOF

chmod +x /usr/local/sbin/*