#!/bin/bash

cd /mnt/server

echo "dotnet run index.cs" > start.sh

echo "
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
        Console.WriteLine(\"\nHello world!\");
    }
    }
}
" > index.cs
