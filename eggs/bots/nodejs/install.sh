#!/bin/sh

echo "node index.js" > start.sh
chmod +x start.sh

cat > index.js << 'EOF'
console.log('\nHello world!')
EOF