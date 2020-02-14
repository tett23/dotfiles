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

bindkey "^p" fzf-file-widget

__find_pid() {
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  echo $pid
}

__select_git_status_items() {
  local items=$(git status -s | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) -m "$@" --preview "git diff --color {2}")
  for item in $items; do
    echo -n $(echo $item | awk '{print $2} ')
  done
  local ret=$?
  echo
  return $ret
}

__git_rebase_interactive() {
  local number=$(git log --oneline --decorate | nl | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) "$@" --preview 'git log --numstat --color {2}')
  if [ "x$number" != "x" ]
  then
    echo -n "git rebase -i HEAD~$(echo $number | awk '{print $1} ')"
  fi
}

__git_log_oneline_commit_hash() {
  local items=$(git log --oneline --decorate | nl | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd)  -m "$@" --preview 'git log --numstat --color {2}')
  for item in $items; do
    echo -n $(echo $item | awk '{print $2} ')
  done
  local ret=$?
  echo
  return $ret
}

__git_log_oneline_commit_number() {
  local items=$(git log --oneline --decorate | nl | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd)  -m "$@" --preview 'git log --numstat --color {2}')
  for item in $items; do
    echo -n $(echo $item | awk '{print $1} ')
  done
  local ret=$?
  echo
  return $ret
}

__docker_container_id() {
  local items=$(docker ps | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) -m "$@")
  for item in $items; do
    echo -n $(echo $item | awk '{print $1} ')
  done
  local ret=$?
  echo
  return $ret
}

__docker_stop_container() {
  local cid=$(__docker_container_id)

  if [ "x$cid" != "x" ]
  then
    docker stop $cid
  fi
}

__docker_image_id() {
  local items=$(docker images | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) -m "$@")
  for item in $items; do
    echo -n $(echo $item | awk '{print $3} ')
  done
  local ret=$?
  echo
  return $ret
}

__docker_remove_image() {
  local image_id=$(__docker_image_id)

  if [ "x$image_id" != "x" ]
  then
    docker rmi --force $image_id
  fi
}

fzf_command_finder() {
  local commands=(
    'select_git_status_items'
    "git_rebase_interactive"
    'git_log_oneline_commit_hash'
    'git_log_oneline_commit_number'
    'docker_container_id'
    'docker_image_id'
    'docker_stop_container'
    'docker_remove_image'
    'repo'
    'fbr'
    'fkill'
    'find_pid'
  )
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
