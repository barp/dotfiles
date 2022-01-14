#!/bin/bash
sudo cp -r ./themes/archcraft/ /usr/share/sddm/themes/

sudo mkdir -p /etc/sddm.conf.d/
sudo cp theme.conf /etc/sddm.conf.d/
