# fzf installed by Homebrew.
source /opt/homebrew/opt/fzf/shell/key-bindings.zsh 2>/dev/null || \
    source /usr/local/opt/fzf/shell/key-bindings.zsh 2>/dev/null
source /opt/homebrew/opt/fzf/shell/completion.zsh 2>/dev/null || \
    source /usr/local/opt/fzf/shell/completion.zsh 2>/dev/null

TIMEFMT='%J   %U  user %S system %P cpu %*E total'$'\n'\
'avg shared (code):         %X KB'$'\n'\
'avg unshared (data/stack): %D KB'$'\n'\
'total (sum):               %K KB'$'\n'\
'max memory:                %M KB'$'\n'\
'page faults from disk:     %F'$'\n'\
'other page faults:         %R'

prepend_path "/opt/homebrew/opt/openjdk/bin"
prepend_path "/opt/homebrew/opt/mysql-client/bin"
export LDFLAGS="-L/opt/homebrew/opt/mysql-client/lib"
export CPPFLAGS="-I/opt/homebrew/opt/mysql-client/include"
