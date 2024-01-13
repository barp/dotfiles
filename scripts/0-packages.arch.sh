#!/bin/bash
# shellcheck disable=2046
yay -S --noconfirm --needed $(cat packages.arch.txt)
