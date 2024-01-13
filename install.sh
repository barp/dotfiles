#!/bin/bash
if command -v pacman &>/dev/null; then
	./0-packages.arch.sh
elif command -v apt-get &>/dev/null; then
	./0-packages.debian.sh
elif [[ "$OSTYPE" == "darwin"* ]]; then
  ./0-packages.darwin.sh
else
	echo "Unsupported distrobution"
fi

./install-zsh.sh

find . -maxdepth 1 -type d -regex '\./[^.]*' -not -regex '.*-mac$' -not -regex '^system$' | stow
