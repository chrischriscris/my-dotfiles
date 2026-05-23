# .zshenv runs for EVERY zsh invocation (interactive, scripts, ssh, cron).
# Keep this file fast and side-effect-free: env vars and PATH only.
# Anything that defines shell functions, prints, or needs a TTY belongs in .zshrc.

# Project secrets and editor preference.
# envsubst expands $VAR references inside ~/.env before exporting.
[ -r ~/.env ] && export $(envsubst < ~/.env)

# Toolchain roots — needed by non-interactive build tools (gradle, maven, go).
export JAVA_HOME="/usr/lib/jvm/default"
export ANDROID_HOME="$HOME/Android/Sdk"
export NVM_DIR="$HOME/.nvm"

# Hyros workspace.
export H_DIR="$HOME/hyros-services"

# PATH additions. Inlined (not via the append_path function from .zshrc)
# because .zshrc isn't loaded yet for non-interactive shells.
_zshenv_add_path() {
  case ":$PATH:" in
    *:"$1":*) ;;
    *) PATH="${PATH:+$PATH:}$1" ;;
  esac
}
_zshenv_add_path "$HOME/.local/bin"
_zshenv_add_path "$HOME/bin"
_zshenv_add_path "$ANDROID_HOME/emulator"
_zshenv_add_path "$ANDROID_HOME/platform-tools"
_zshenv_add_path "$HOME/go/bin"
# Default node from nvm — so scripts and IDEs see `node` without lazy-loading nvm.
if [ -r "$NVM_DIR/alias/default" ]; then
  _nvm_default="$(<"$NVM_DIR/alias/default")"
  [ "${_nvm_default#v}" = "$_nvm_default" ] && _nvm_default="v$_nvm_default"
  [ -d "$NVM_DIR/versions/node/$_nvm_default/bin" ] && \
    _zshenv_add_path "$NVM_DIR/versions/node/$_nvm_default/bin"
  unset _nvm_default
fi
unset -f _zshenv_add_path
export PATH
