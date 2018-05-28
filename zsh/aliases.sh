if [[ -x `which colordiff` ]]; then
  alias diff='colordiff -u'
fi
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

fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}
zle -N fkill
alias pskill='(){ fkill }'
bindkey "^K" fkill

bindkey "^p" fzf-file-widget

# fbr - checkout git branch (including remote branches), sorted by most recent commit
fbr() {
  local branches branch
  branch=$(git branch --all --sort=committerdate --color | grep -v HEAD | fzf-tmux -d 30% --no-sort --reverse --tac)
  ret=$(echo -n $branch | sed "s/.* //")

  echo -n $ret

  return ret
}
zle -N fbr
alias fzf-branch='(){ fbr }'
bindkey "^B" fbr


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
