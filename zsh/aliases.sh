if [[ -x `which colordiff` ]]; then
  alias diff='colordiff -u'
fi
alias where="command -v"
alias j="jobs -l"
alias g="git"
alias gi="git"
alias gti="git"
alias la="ls -a"
alias lf="ls -F"
alias ll="ls -l"
alias llh="ls -lh"
alias du="du -h"
alias df="df -h"
alias su="su -l"
alias gg="git grep --ignore-case --color"
alias yw="yarn workspace"
alias be="bundle exec"

LESS="-R"

if which nvim >/dev/null 2>&1; then
  alias vim=nvim
fi

if command -v python3 >/dev/null 2>&1; then
  alias python="python3"
fi

if command -v gsed >/dev/null 2>&1; then
  alias sed="gsed"
fi

if command -v gawk >/dev/null 2>&1; then
  alias awk="gawk"
fi
