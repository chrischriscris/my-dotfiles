# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=20000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

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

parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

PS1='\[\e[1;32m\][\u]\[\e[0m\e[1;31m\] \W/\[\e[0m\e[1;34m\]$(parse_git_branch)\[\033[00m\] $ \[\e[0m\]'

# enable color support of ls and also add handy aliases
test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"

# color for manpages in less makes manpages a little easier to read
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# import aliases and extra bash completions

. ~/.bash_aliases
# . /etc/bash_completion
for file in /etc/bash_completion.d/* ; do
  source "$file"
done

# ====================================================================

# add all files in the directory and commit the given message
lazypush () {
    git add .;
    git commit -a -m "$1";
    git push
}

# For tilix terminal emulator
if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
        source /etc/profile.d/vte.sh
fi

# ==== Custom path additions ====

prepend_path "/usr/local/texlive/2023/bin/x86_64-linux"
append_path "$HOME/.local/bin" # pipx executables
append_path "$HOME/bin" # Custom scripts

# ==== They want to be at the end ====

# Set up Node Version Manager
source /usr/share/nvm/init-nvm.sh

# Set up java home
export JAVA_HOME="/usr/lib/jvm/default"

# RVM bash completion
[[ -r "$HOME/.rvm/scripts/completion" ]] && source "$HOME/.rvm/scripts/completion"

# Load RVM into a shell session *as a function*
[[ -r "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

append_path "$HOME/.rvm/bin" # RVM, make sure this is the last PATH variable change.
