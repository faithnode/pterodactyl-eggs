#!/bin/sh

echo "php index.php" > start.sh
chmod +x start.sh

cat > index.php << 'EOF'
<?php

echo "\nHello world!\n";
EOF
