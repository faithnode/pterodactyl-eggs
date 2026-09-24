#!/bin/sh

source ../../../scripts/prepare.sh

echo "rustc main.rs && ./main" > start.sh
chmod +x start.sh

cat > main.rs << 'EOF'
fn main() {
    println!("\nHello world!");
}
EOF
