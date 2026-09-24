#!/bin/sh

echo "ruby index.rb" > start.sh
chmod +x start.sh

cat > index.rb << 'EOF'
puts "\nHello world!"
EOF