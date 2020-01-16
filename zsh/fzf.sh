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
bindkey "^b" fbr

__fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}

fkill() {
  LBUFFER="${LBUFFER}$(__fkill)"
  local ret=$?
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}
zle -N fkill
bindkey "^K" fkill

__docker_stop() {
  local cid
  cid=$(docker ps | sed 1d | fzf -m | awk '{print $1}')

  if [ "x$cid" != "x" ]
  then
    echo "stop container $cid"
    docker stop $cid
  fi
}

docker_stop() {
  LBUFFER="${LBUFFER}$(__docker_stop)"
  local ret=$?
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}
zle -N docker_stop
bindkey "^f" docker_stop

bindkey "^p" fzf-file-widget

__select_git_status_items() {
  local items=$(git status -s | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) -m)
  for item in $items; do
    echo -n $(echo $item | awk '{print $2} ')
  done
  local ret=$?
  echo
  return $ret
}

fzf_command_finder() {
  local commands=('select_git_status_items' 'repo' 'fbr' 'fkill' 'docker_stop')
  local joined
  joined=$(printf "\n%s" "${commands[@]}")
  joined=${joined:1}

  local cmd
  cmd=$(echo $joined | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) +m)
  if [ "x$cmd" != "x" ]
  then
    LBUFFER="${LBUFFER}$(__$cmd)"
  fi

  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
}

zle -N fzf_command_finder
bindkey "^n" fzf_command_finder
