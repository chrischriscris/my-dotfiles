# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
ZSH=/usr/share/oh-my-zsh/

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
  mkdir $ZSH_CACHE_DIR
fi

. $ZSH/oh-my-zsh.sh

. /usr/share/fzf/key-bindings.zsh
. /usr/share/fzf/completion.zsh


# =========== My configuration ===========

# Custom time command
if [[ `uname` == Darwin ]]; then
    MAX_MEMORY_UNITS=KB
else
    MAX_MEMORY_UNITS=MB
fi

TIMEFMT='%J   %U  user %S system %P cpu %*E total'$'\n'\
'avg shared (code):         %X KB'$'\n'\
'avg unshared (data/stack): %D KB'$'\n'\
'total (sum):               %K KB'$'\n'\
'max memory:                %M '$MAX_MEMORY_UNITS''$'\n'\
'page faults from disk:     %F'$'\n'\
'other page faults:         %R'

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

# Add all files in the directory and commit the given message
lazypush () {
    git add .;
    git commit -a -m "$1";
    git push
}

# Custom path addtions
export $(envsubst < ~/.env)

export ANDROID_HOME="$HOME/Android/Sdk"
append_path "$HOME/.local/bin" # pipx executables
append_path "$HOME/bin" # Custom scripts
append_path "$ANDROID_HOME/emulator"
append_path "$ANDROID_HOME/platform-tools"

# Commands that want to run at the end of the file

# Set up java home
export JAVA_HOME="/usr/lib/jvm/default"

# RVM bash completion
[[ -r "$HOME/.rvm/scripts/completion" ]] && source "$HOME/.rvm/scripts/completion"

# Load RVM into a shell session *as a function*
[[ -r "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

append_path "$HOME/.rvm/bin" # RVM, make sure this is the last PATH variable change.

