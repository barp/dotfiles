#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

. "$HOME/.local/share/../bin/env"
. "$HOME/.cargo/env"
. "/home/bar/.deno/env"
source /home/bar/.local/share/bash-completion/completions/deno.bash
