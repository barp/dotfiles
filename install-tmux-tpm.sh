#!/bin/bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

cat <<EOF >> ~/.tmux.conf
set -g @plugin 'tmux-plugins/tpm'

run '~/.tmux/plugins/tpm/tpm'
EOF
