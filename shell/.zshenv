# rustup only - Arch's rust package puts cargo on PATH with no env file.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
