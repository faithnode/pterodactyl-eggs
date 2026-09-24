#!/bin/sh

source ../../../scripts/prepare.sh

echo "go run index.go" > start.sh
chmod +x start.sh

cat > index.go << 'EOF'
package main
import "fmt"

func main() {
    fmt.Println("\nHello world!")
}
EOF