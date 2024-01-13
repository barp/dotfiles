#!/bin/bash

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install stow

brew tap homebrew/cask-fonts

brew install font-inconsolata-nerd-font
brew install fzf
brew install tmux
brew install --cask font-caskaydia-cove-nerd-font                                                                              │
brew install python@3.9                                                                                                        │
brew install terraform
brew install ripgrep
brew install npm
brew install nvim
brew install --cask alacritty

pip install gita

stow alacritty-mac
