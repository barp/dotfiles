#!/bin/bash
if command -v pacman &>/dev/null; then
	./scripts/0-packages.arch.sh
elif command -v apt-get &>/dev/null; then
	./scripts/0-packages.debian.sh
elif [[ "$OSTYPE" == "darwin"* ]]; then
  ./scripts/0-packages.darwin.sh
else
	echo "Unsupported distrobution"
fi

./scripts/install-zsh.sh
./scripts/install-tpm.sh
./scripts/install-nvchad.sh
./scripts/stow-generic.sh
