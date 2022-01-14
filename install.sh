#!/bin/bash
if command -v pacman &> /dev/null; then
    ./0-packages.arch.sh
elif command -v apt-get &> /dev/null; then
    ./0-packages.debian.sh
else
    echo "Unsupported distrobution"
fi

find . -maxdepth 1 -type d -regex '\./[^.]*' -not -regex '.*-mac$' | stow
