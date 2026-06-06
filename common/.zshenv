# .zshenv runs for EVERY zsh invocation (interactive, scripts, ssh, cron).
# Keep this file fast and side-effect-free: env vars and PATH only.
# Anything that defines shell functions, prints, or needs a TTY belongs in .zshrc.

# Project secrets and editor preference. Export assignments while loading the
# local file without depending on external commands during shell startup.
if [ -r "$HOME/.env" ]; then
  set -a
  . "$HOME/.env"
  set +a
fi

# Toolchain roots needed by non-interactive build tools.
if [ "$(uname -s)" = Darwin ]; then
  export JAVA_HOME="$(/usr/libexec/java_home 2>/dev/null || printf '%s' '/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home')"
  export ANDROID_HOME="$HOME/Library/Android/sdk"
else
  export JAVA_HOME="/usr/lib/jvm/default"
  export ANDROID_HOME="$HOME/Android/Sdk"
fi
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
