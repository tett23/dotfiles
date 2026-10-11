if (( $+commands[colordiff] )); then
  alias diff='colordiff -u'
fi

alias where="command -v"
alias j="jobs -l"
alias g="git"
alias gi="git"
alias gti="git"
alias la="ls -la"
alias lf="ls -F"
alias ll="ls -l"
alias llh="ls -lh"
alias du="du -h"
alias df="df -h"
alias su="su -l"
alias gg="git grep --ignore-case --color"
alias yw="yarn workspace"
alias be="bundle exec"
alias fig='docker compose'

if (( $+commands[nvim] )); then
  alias vim=nvim
fi

# eza (ls の代わり) と bat (cat の代わり) の短いエイリアス (docs/adr/0035)
if (( $+commands[eza] )); then
  alias e="eza"
  alias el="eza -l"
  alias ea="eza -a"
  alias ela="eza -la"
  alias et="eza --tree"
fi
if (( $+commands[bat] )); then
  alias b="bat"
fi

if (( $+commands[python3] )); then
  alias python="python3"
fi

if (( $+commands[gsed] )); then
  alias sed="gsed"
fi

if (( $+commands[gawk] )); then
  alias awk="gawk"
fi
