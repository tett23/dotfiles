# fzf を使うコマンド。__<名前> の関数の直前の 1 行のコメントは、コマンド選択 (Ctrl-O) に出す説明 (docs/adr/0033)
typeset -g _fzf_commands_file=${(%):-%x}

# ghq のリポジトリを選び、パスを入力行に足す
__repo() {
  local cmd="ghq list -p"
  setopt localoptions pipefail 2> /dev/null
  eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS" $(__fzfcmd) -m "$@" | while read item; do
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

# git のブランチ (リモートを含む、更新順) を選び、入力行に足す
__fbr() {
  local branches branch
  local cmd="git branch --all --sort=committerdate --color | grep -v HEAD | sed 's/.* //' | sed 's/remotes\///'"

  setopt localoptions pipefail 2> /dev/null
  eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS" $(__fzfcmd) -m "$@" | while read item; do
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

# プロセスを選んで終了させる (既定は kill -9)
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

# node_modules のパッケージを選び、パスを入力行に足す
__find_node_modules(){
  find_node_packages $(pwd)| jq -r '.[] | [.name + "@" + .version + " " + .path] | .[]' | fzf | awk '{print $2}'
}

# プロセスを選び、PID を入力行に足す
__find_pid() {
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  echo $pid
}

# git status のファイルを選び、入力行に足す
__select_git_status_items() {
  local items=$(git status -s | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS" $(__fzfcmd) -m "$@" --preview "git diff --color {2}")
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

# コミットを選び、そこまでの git rebase -i のコマンドを入力行に足す
__git_rebase_interactive() {
  local number=$(git log --oneline --decorate | nl | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS" $(__fzfcmd) "$@" --preview 'git log --numstat --color {2}')
  if [ "x$number" != "x" ]
  then
    echo -n "git rebase -i HEAD~$(echo $number | awk '{print $1} ')"
  fi
}

# 廃止された hub の代わりに gh を使う。3 列目がブランチ名の形式は hub 時代と同じ (docs/adr/0010)。
# (次の行はコマンド選択に出す説明。docs/adr/0033)
# プルリクエストを選び、ブランチ名を入力行に足す
__gh_pr_branch() {
  local branch=$(gh pr list --limit 50 --json number,author,headRefName,state,title \
    --jq '.[] | "#\(.number) \(.author.login) \(.headRefName) \(.state) \(.title)"' | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS" $(__fzfcmd) "$@")
  if [ "x$branch" != "x" ]
  then
    echo -n "$(echo $branch | awk '{print $3} ')"
  fi
}

# コミットを選び、ハッシュを入力行に足す
__git_log_oneline_commit_hash() {
  local items=$(git log --oneline --decorate | nl | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS" $(__fzfcmd)  -m "$@" --preview 'git log --numstat --color {2}')
  for item in $items; do
    echo -n $(echo $item | awk '{print $2} ')
  done
  local ret=$?
  echo
  return $ret
}

# コミットを選び、HEAD からの番号を入力行に足す
__git_log_oneline_commit_number() {
  local items=$(git log --oneline --decorate | nl | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS" $(__fzfcmd)  -m "$@" --preview 'git log --numstat --color {2}')
  for item in $items; do
    echo -n $(echo $item | awk '{print $1} ')
  done
  local ret=$?
  echo
  return $ret
}

# docker のコンテナを選び、ID を入力行に足す
__docker_container_id() {
  local items=$(docker ps | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS" $(__fzfcmd) -m "$@")
  for item in $items; do
    echo -n $(echo $item | awk '{print $1} ')
  done
  local ret=$?
  echo
  return $ret
}

# docker のコンテナを選んで止める
__docker_stop_container() {
  local cid=$(__docker_container_id)

  if [ "x$cid" != "x" ]
  then
    docker stop $cid
  fi
}

# docker のイメージを選び、ID を入力行に足す
__docker_image_id() {
  local items=$(docker images | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS" $(__fzfcmd) -m "$@")
  for item in $items; do
    echo -n $(echo $item | awk '{print $3} ')
  done
  local ret=$?
  echo
  return $ret
}

# docker のイメージを選んで削除する
__docker_remove_image() {
  local image_id=$(__docker_image_id)

  if [ "x$image_id" != "x" ]
  then
    docker rmi --force $image_id
  fi
}

# yarn のワークスペースを選び、名前を入力行に足す
__yarn_workspaces(){
  yarn workspaces --silent info | jq 'keys | .[]' | fzf
}

# tmux の全セッションのウィンドウを選んで切り替える。入力行には何も足さない
__ftmux_window() {
  [[ -n ${TMUX-} ]] || return 0
  local current target
  current=$(tmux display-message -p -t "${TMUX_PANE-}" '#{session_name}:#{window_index}')
  target=$(tmux list-windows -a -F $'#{session_name}:#{window_index}\t#{b:pane_current_path}  #{pane_current_command}' |
    while IFS=$'\t' read -r win rest; do
      print -r -- "$win"$'\t'"${${win:#$current}:+ }${${(M)win:#$current}:+*} $rest"
    done |
    FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS" $(__fzfcmd) +m \
      --delimiter=$'\t' --preview 'tmux capture-pane -ep -t {1}' | cut -f1)
  [[ -n $target ]] || return 0
  tmux select-window -t "$target" && tmux switch-client -t "${target%:*}"
}

ftmux_window() {
  __ftmux_window
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
}

# コマンド選択の一覧。このファイルで定義した __<名前> の関数を「名前・キー・説明」の 1 行ずつで出す。
# キーは同名のウィジェットの割り当て (現在のキーマップ)、説明は関数の直前の 1 行のコメント (docs/adr/0033)
fzf_command_names() {
  local -A descs
  local prev='' line
  for line in "${(@f)$(<$_fzf_commands_file)}"; do
    [[ $line =~ '^__([A-Za-z0-9_]+) *\(\)' && $prev == '# '* ]] && descs[${match[1]}]=${prev#\# }
    prev=$line
  done

  local fn name key
  for fn in ${(ok)functions_source}; do
    [[ $fn == __* && ${functions_source[$fn]} == $_fzf_commands_file ]] || continue
    name=${fn#__}
    key=${${(z)$(bindkey -M main | grep -E " ${name}\$" | head -1)}[1]-}
    printf '%-30s %-4s %s\n' "$name" "${(Q)key}" "${descs[$name]-}"
  done
}

fzf_command_finder() {
  local cmd
  cmd=$(fzf_command_names | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS" $(__fzfcmd) +m | awk '{print $1}')
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
# Ctrl-O (旧 "^," は実際には Ctrl-L に割り当たり、画面のクリアを潰していた。docs/adr/0031)
bindkey "^o" fzf_command_finder
zle -N fkill
bindkey "^k" fkill
zle -N ftmux_window
bindkey "^t" ftmux_window # tmux のウィンドウの切り替え (docs/adr/0033, 0036)。fzf 本体の Ctrl-T (ファイルの選択) は Ctrl-P で使う
bindkey "^p" fzf-file-widget
zle -N select_git_status_items
bindkey "^f" select_git_status_items

# fzf
export FZF_DEFAULT_OPTS="--ansi --extended --cycle"
# ファイル検索は fd (macOS の BSD find は引数なしで失敗する。docs/adr/0002 参照)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# Ctrl-P (fzf-file-widget。fzf 本体の Ctrl-T の機能) でファイルの先頭をプレビューする。独自のコマンドにはこの変数を渡さない (docs/adr/0034)
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
