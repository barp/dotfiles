#!/bin/bash
# ! NOT TESTED

# --------------------------
# Install common build helpers
# --------------------------
sudo apt-get install cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3 libxtst-dev libx11-dev make gcc git meson 

# install latest rust builder
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# --------------------------
# Install alacritty
# --------------------------


git clone https://github.com/alacritty/alacritty.git
pushd alacritty
cargo install alacritty
popd
rm -rf alacritty


git clone https://github.com/ryanoasis/nerd-fonts.git
pushd nerd-fonts
./install.sh
popd
rm -rf nerd-fonts


# --------------------------
# Install packages
# --------------------------

sudo apt-get install \
  python3-pip stow 

# Will take care of later
# betterlockscreen

# Probably optional
#gvfs gvfs-mtp gvfs-afc gvfs-gphoto2 gvfs-smb gvfs-google
