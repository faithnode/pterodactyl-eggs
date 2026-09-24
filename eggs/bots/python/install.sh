#!/bin/sh

source ../../../scripts/prepare.sh

echo "python index.py" > start.sh
chmod +x start.sh

cat > index.py << 'EOF'
print("\nHello world!")
EOF