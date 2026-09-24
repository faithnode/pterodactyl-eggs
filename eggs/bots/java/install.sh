#!/bin/sh

echo "java Main.java" > start.sh
chmod +x start.sh

cat > Main.java << 'EOF'
public class Main {
    public static void main(String[] args) {
        System.out.println("\nHello world!");
    }
}
EOF