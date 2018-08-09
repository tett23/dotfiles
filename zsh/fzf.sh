__repo() {
  local cmd="ghq list -p"
  setopt localoptions pipefail 2> /dev/null
  eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) -m "$@" | while read item; do
    echo -n "${(q)item} "
  done
  local ret=$?
  echo
  return $ret
}

function repo() {
  LBUFFER="${LBUFFER}$(__repo)"
  local ret=$?
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}

zle -N repo
bindkey "^g" repo

__fbr() {
  local branches branch
  local cmd="git branch --all --sort=committerdate --color | grep -v HEAD | sed 's/.* //' | sed 's/remotes\///'"

  setopt localoptions pipefail 2> /dev/null
  eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) -m "$@" | while read item; do
    echo -n "${(q)item} "
  done
  local ret=$?
  echo
  return $ret
}

# fbr - checkout git branch (including remote branches), sorted by most recent commit
fbr() {
  LBUFFER="${LBUFFER}$(__fbr)"
  local ret=$?
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}
zle -N fbr
alias fzf-branch='(){ fbr }'
bindkey "^b" fbr

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

docker_stop() {
  local cid
  cid=$(docker ps | sed 1d | fzf -m | awk '{print $1}')

  if [ "x$cid" != "x" ]
  then
    echo "stop container $cid"
    docker stop $cid
  fi
}
zle -N docker_stop
bindkey "^f" docker_stop

bindkey "^p" fzf-file-widget
