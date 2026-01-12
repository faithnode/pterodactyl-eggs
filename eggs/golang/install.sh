#!/bin/bash

cd /mnt/server

echo "go run index.go" > start.sh

echo "
package main
import \"fmt\"
func main() {
    fmt.Println(\"\nHello world!\")
}" > index.go
