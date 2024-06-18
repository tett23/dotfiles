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

__find_node_modules(){
  find_node_packages $(pwd)| jq -r '.[] | [.name + "@" + .version + " " + .path] | .[]' | fzf | awk '{print $2}'
}

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

select_git_status_items() {
  LBUFFER="${LBUFFER}$(__select_git_status_items)"
  local ret=$?
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}

__git_rebase_interactive() {
  local number=$(git log --oneline --decorate | nl | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) "$@" --preview 'git log --numstat --color {2}')
  if [ "x$number" != "x" ]
  then
    echo -n "git rebase -i HEAD~$(echo $number | awk '{print $1} ')"
  fi
}

__gh_pr_branch() {
  local branch=$(hub pr list --format "%i %au %H %pS %t%n" --limit 50 | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) "$@")
  if [ "x$branch" != "x" ]
  then
    echo -n "$(echo $branch | awk '{print $3} ')"
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

__yarn_workspaces(){
  yarn workspaces --silent info | jq 'keys | .[]' | fzf
}

fzf_command_finder() {
  local commands=(
    'select_git_status_items'
    'git_rebase_interactive'
    'yarn_workspaces'
    'gh_pr_branch'
    'git_log_oneline_commit_hash'
    'git_log_oneline_commit_number'
    'docker_container_id'
    'docker_image_id'
    'docker_stop_container'
    'docker_remove_image'
    'find_node_modules'
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

zle -N repo
bindkey "^g" repo
zle -N fbr
bindkey "^b" fbr
zle -N fzf_command_finder
bindkey "^n" fzf_command_finder
export FZF_CTRL_T_COMMAND=find
zle -N fkill
bindkey "^k" fkill
bindkey "^p" fzf-file-widget
zle -N select_git_status_items
bindkey "^e" select_git_status_items

# fzf
export FZF_DEFAULT_OPTS="--ansi --extended --cycle"
# export FZF_DEFAULT_COMMAND='ag -g ""'
