# uv's installer writes this; it only prepends ~/.local/bin, which .zshrc does too.
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export ANDROID_AVD_HOME=$HOME/.config/.android/avd/

export PATH=$ANDROID_HOME/emulator:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin/:$PATH
export PATH=$(go env GOPATH)/bin:$PATH
export PATH=/opt/binaryen/bin/:$PATH

# opencode
export PATH=/home/bar/.opencode/bin:$PATH

# add Pulumi to the PATH
export PATH=$PATH:/home/bar/.pulumi/bin

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/bar/.local/share/mise/installs/python/miniconda3-4.7.12/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/bar/.local/share/mise/installs/python/miniconda3-4.7.12/etc/profile.d/conda.sh" ]; then
        . "/home/bar/.local/share/mise/installs/python/miniconda3-4.7.12/etc/profile.d/conda.sh"
    else
        export PATH="/home/bar/.local/share/mise/installs/python/miniconda3-4.7.12/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH=$PATH:/opt/Antigravity/
export TF_PLUGIN_CACHE_DIR=$HOME/.cache/terraform/

export PATH="/home/bar/.moon/bin:$PATH"
. <(mise env)
