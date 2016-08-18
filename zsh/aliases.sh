alias diff="colordiff"
alias where="command -v"
alias j="jobs -l"
alias g="git"
alias la="ls -a"
alias lf="ls -F"
alias ll="ls -l"
alias du="du -h"
alias df="df -h"
alias su="su -l"
alias gg="git grep --ignore-case"

if which nvim >/dev/null 2>&1; then
  alias vim=nvim
fi

case "${OSTYPE}" in
freebsd*|darwin*)
  alias ls="ls -G -w"
  ;;
linux*)
  alias ls="ls --color"
  ;;
esac
