# ASCII BOAT SHELL INTEGRATION START boat
case ":$PATH:" in
  *":/Users/chus/.ascii/bin:"*) ;;
  *) PATH="/Users/chus/.ascii/bin:$PATH" ;;
esac
export PATH
# ASCII BOAT SHELL INTEGRATION END boat

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ZSH="$HOME/.oh-my-zsh"
else
    ZSH="/usr/share/oh-my-zsh"
fi

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
zstyle ':omz:plugins:nvm' lazy yes
plugins=(
    git
    nvm
    zsh-autosuggestions
)

# export MANPATH="/usr/local/man:$MANPATH"

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

ZSH_CACHE_DIR=$HOME/.cache/oh-my-zsh
if [[ ! -d $ZSH_CACHE_DIR ]]; then
  mkdir -p "$ZSH_CACHE_DIR"
fi
ZSH_DISABLE_COMPFIX=true

[[ -r "$ZSH/oh-my-zsh.sh" ]] && . "$ZSH/oh-my-zsh.sh"

# =========== My configuration ===========

# Custom aliases
. ~/.bash_aliases
# for file in /etc/bash_completion.d/* ; do
#   source "$file"
# done

# Custom functions
prepend_path() {
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            export PATH="$1${PATH:+:$PATH}"
    esac
}

append_path() {
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            export PATH="${PATH:+$PATH:}$1"
    esac
}

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Wrap ~/bin/wt so the new worktree becomes the current directory. A script
# alone cannot do this: it runs in a child process and can only cd itself.
function wt() {
	local dir
	dir=$(command wt "$@") || return $?
	builtin cd -- "$dir"
}

append_path "$HOME/.local/bin" # pipx executables
append_path "$HOME/bin" # Custom scripts
append_path "$ANDROID_HOME/emulator"
append_path "$ANDROID_HOME/platform-tools"
append_path "$HOME/go/bin"

# Commands that want to run at the end of the file

# RVM bash completion
[[ -r "$HOME/.rvm/scripts/completion" ]] && source "$HOME/.rvm/scripts/completion"

# Load RVM into a shell session *as a function*
[[ -r "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

append_path "$HOME/.rvm/bin" # RVM, make sure this is the last PATH variable change.
# Hyros config
export H_DIR=$HOME/hyros-services
# The MFA session written by aws-mfa; the base keys in the default profile are denied without MFA.
export AWS_PROFILE=mfa

# Interactive settings selected by the active Stow platform package.
[[ -r "$HOME/.config/zsh/platform.zsh" ]] && \
    source "$HOME/.config/zsh/platform.zsh"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
sdk() {
    unset -f sdk
    if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
        sdk "$@"
    else
        print -u2 "sdkman init script not found: $SDKMAN_DIR/bin/sdkman-init.sh"
        return 127
    fi
}

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<

# === agent-worktree BEGIN ===
# NOTE: Don't use 'path'/'status' as variable names - zsh reserves them
wt() {
  local wt_bin path_file target_path wt_status wt_arg path_file_inserted
  local -a wt_args
  if [[ -n "$ZSH_VERSION" ]]; then
    wt_bin=$(whence -p wt 2>/dev/null)
  else
    wt_bin=$(type -P wt 2>/dev/null)
  fi
  if [[ -z "$wt_bin" ]]; then
    echo "wt: binary not found. Install: npm install -g agent-worktree" >&2
    return 1
  fi
  # Pass through if -h/--help anywhere in args
  case " $* " in
    *" -h "*|*" --help "*) "$wt_bin" "$@"; return ;;
  esac
  case "$1" in
    cd|new|rm|mv|merge|clean|run)
      # Use mktemp so concurrent calls (and subshells where $$ is the parent
      # PID) get unique files; fall back to PID-based name if mktemp missing.
      path_file=$(mktemp 2>/dev/null) || path_file="${TMPDIR:-/tmp}/wt-path-$$"
      # `wt run -- <agent>` treats every argument after `--` as belonging to
      # the agent, so inject the wrapper option before that delimiter.
      wt_args=()
      path_file_inserted=
      for wt_arg in "$@"; do
        if [[ "$wt_arg" == "--" && -z "$path_file_inserted" ]]; then
          wt_args+=(--path-file "$path_file")
          path_file_inserted=1
        fi
        wt_args+=("$wt_arg")
      done
      if [[ -z "$path_file_inserted" ]]; then
        wt_args+=(--path-file "$path_file")
      fi
      "$wt_bin" "${wt_args[@]}"
      wt_status=$?
      # -s guards the empty file mktemp created: cd only on a written target
      if [[ $wt_status -eq 0 && -s "$path_file" ]]; then
        target_path=$(<"$path_file"); cd "$target_path"
      fi
      rm -f "$path_file"
      return $wt_status
      ;;
    *)
      "$wt_bin" "$@"
      ;;
  esac
}
# Dynamic completions: call binary directly to bypass wt function
if [[ -n "$ZSH_VERSION" ]]; then
  _wt_bin=$(whence -p wt 2>/dev/null)
  [[ -n "$_wt_bin" ]] && source <(COMPLETE=zsh "$_wt_bin" 2>/dev/null) 2>/dev/null
else
  _wt_bin=$(type -P wt 2>/dev/null)
  [[ -n "$_wt_bin" ]] && source <(COMPLETE=bash "$_wt_bin" 2>/dev/null) 2>/dev/null
fi
unset _wt_bin
# === agent-worktree END ===

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform

# bun completions
[ -s "/tmp/bun14/_bun" ] && source "/tmp/bun14/_bun"

# opencode
export PATH=/Users/chus/.opencode/bin:$PATH

# Xcode toolchain for xcrun/simctl (gym-nerds)
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# Added by Devin
export PATH="/Users/chus/.codeium/windsurf/bin:$PATH"

# MiniMax Code CLI
export PATH="/Users/chus/.minimax-code/bin:$PATH"

# Added by MiniMax Code
export PATH="/Users/chus/.minimax/bin:$PATH"

# mimocode
export PATH=/Users/chus/.mimocode/bin:$PATH

# ASCII BOAT SHELL INTEGRATION START boat
boat() {
  current_file=$(mktemp)
  convo_file=$(mktemp)
  old_current_file=${BOAT_CURRENT_ID_FILE-}
  old_convo_file=${BOAT_CURRENT_CONVO_FILE-}
  export BOAT_CURRENT_ID_FILE="$current_file"
  export BOAT_CURRENT_CONVO_FILE="$convo_file"
  command "/Users/chus/.ascii/bin/boat" "$@"
  boat_status=$?
  if [ "$boat_status" -eq 0 ]; then
    case "${1:-}" in
      new|start|fork)
        if [ -s "$current_file" ]; then
          current_id=$(tr -d '[:space:]' < "$current_file")
          if [ -n "$current_id" ]; then export BOAT_CURRENT_ID="$current_id"; fi
        fi
        ;;
    esac
    case "${1:-}" in
      prompt)
        if [ -s "$convo_file" ]; then
          IFS= read -r current_convo < "$convo_file" || current_convo=""
          if [ -n "$current_convo" ]; then export BOAT_CURRENT_CONVO="$current_convo"; fi
        fi
        ;;
    esac
  fi
  if [ -n "$old_current_file" ]; then export BOAT_CURRENT_ID_FILE="$old_current_file"; else unset BOAT_CURRENT_ID_FILE; fi
  if [ -n "$old_convo_file" ]; then export BOAT_CURRENT_CONVO_FILE="$old_convo_file"; else unset BOAT_CURRENT_CONVO_FILE; fi
  rm -f "$current_file" "$convo_file"
  return "$boat_status"
}
# ASCII BOAT SHELL INTEGRATION END boat
