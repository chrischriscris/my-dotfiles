# colored output
alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# alias's to modified commands
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -iv'
alias mkdir='mkdir -p'
alias c='clear'
alias n='nnn -A'
alias cat='bat -p'

# safe reboot
alias reboot='sudo shutdown -r now'

# safe shutdown
alias shutdown='sudo shutdown now'

# available memory
alias fm='free -m'

# programs
alias lvim="NVIM_APPNAME=lazyvim nvim"
