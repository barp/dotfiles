#!/bin/bash
# ! NOT TESTED

# --------------------------
# Install common build helpers
# --------------------------
sudo apt-get install cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3 libxtst-dev libx11-dev make gcc git meson stow

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

# --------------------------
# Install ksuperkey
# --------------------------

git clone https://github.com/hanschen/ksuperkey.git
pushd ksuperkey
make
sudo make install
popd
rm -rf ksuperkey

# --------------------------
# Install networkmanager_dmenu
# --------------------------

git clone https://github.com/firecat53/networkmanager-dmenu.git
pushd networkmanager-dmenu
sudo cp networkmanager_dmenu /usr/local/bin/
sudo chmod +x /usr/local/bin/networkmanager_dmenu
popd
rm -rf networkmanager-dmenu

# --------------------------
# Install xfce-polkit
# --------------------------

sudo apt-get install libxfce4ui-2-dev  libglib2.0-dev libpolkit-agent-1-dev
git clone https://github.com/ncopa/xfce-polkit.git
pushd xfce-polkit
mkdir build
cd build
meson --prefix=/usr ..
ninja
sudo ninja install
popd
rm -rf xfce-polkit

# --------------------------
# Install nerd fonts
# --------------------------

git clone https://github.com/ryanoasis/nerd-fonts.git
pushd nerd-fonts
./install.sh
popd
rm -rf nerd-fonts


# --------------------------
# Install packages
# --------------------------

sudo apt-get install rofi bspwm sxhkd dunst xfce4-power-manager \
  network-manager x11-server-utils \
  xsettingsd bmon mpc alsa-utils xsettingsd ranger thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman \
  nitrogen light polybar mpd python3-pip playerctl picom

# Will take care of later
# betterlockscreen

# Probably optional
#gvfs gvfs-mtp gvfs-afc gvfs-gphoto2 gvfs-smb gvfs-google
