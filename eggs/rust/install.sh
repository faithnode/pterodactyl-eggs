#!/bin/bash

cd /mnt/server

echo "rustc index.rs && ./index" > start.sh

echo "
fn main() {
    println!(\"\nHello world!\");
}" > index.rs
