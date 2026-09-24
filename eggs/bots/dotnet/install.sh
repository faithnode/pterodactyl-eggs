#!/bin/sh

source ../../../scripts/prepare.sh

echo "dotnet run Program.cs" > start.sh
chmod +x start.sh

cat > Program.cs << 'EOF'
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ConsoleApp1
{
    class Program
    {
    static void Main(string[] args)
    {
        Console.WriteLine("\nHello world!");
    }
    }
}
EOF
