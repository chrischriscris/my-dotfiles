[[ -r "$HOME/.bashrc" ]] && . "$HOME/.bashrc"
[[ -r "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
[[ -r "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

export SDKMAN_DIR="$HOME/.sdkman"
[[ -r "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && . "$SDKMAN_DIR/bin/sdkman-init.sh"
