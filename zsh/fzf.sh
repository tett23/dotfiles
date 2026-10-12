# fzf を使うコマンド。__<名前> の関数の直前の 1 行のコメントは、コマンド選択 (Ctrl-O) に出す説明 (docs/adr/0033)
typeset -g _fzf_commands_file=${(%):-%x}

# fzf を呼ぶ共通の処理。$1 は並べ方などの追加のオプション、残りは fzf にそのまま渡す。
# 共通の指定 (高さなど) は fzf 本体の __fzf_defaults に任せる (docs/adr/0046)。__ を付けないので Ctrl-O の一覧には出ない
_fzf_run() {
  local layout=$1
  shift
  FZF_DEFAULT_OPTS="$(__fzf_defaults "$layout" '')" ${=$(__fzfcmd)} "$@"
}

# 以下は fzf の入出力を解析する純粋な関数 (zsh/tests/fzf-parse.test.zsh でテストする。docs/adr/0046)

# git status --short -z の出力 (NUL 区切り) を、fzf に渡す 1 要素 1 行にする。名前の変更・コピーは変更後のパスだけにする
fzf_git_status_lines() {
  local -a entries=(${(0)"$(command cat)"})
  local -i i=1
  while (( i <= $#entries )); do
    print -r -- ${entries[i]}
    [[ ${entries[i]} == [RC]* ]] && (( i++ ))
    (( i++ ))
  done
}

# 各行の n 列目 (空白区切り) を取り出し、空白でつないで 1 行にする。入力が空なら何も出さない
fzf_fields() {
  local -a values=(${(f)"$(awk -v n="$1" '{ print $n }')"})
  (( $#values )) && print -rn -- "${(j: :)values}"
}

# git status --short の行から状態の 3 文字を外したパスを、シェルの引用をしてつなぐ。入力が空なら何も出さない
fzf_status_paths() {
  local -a lines=(${(f)"$(command cat)"})
  (( $#lines )) && print -rn -- "${(j: :)${(@q)lines#???}}"
}

# ghq のリポジトリを選び、パスを入力行に足す
__repo() {
  local out
  out=$(ghq list -p | _fzf_run --reverse -m "$@") || return
  print -rn -- "${(j: :)${(@qf)out}} "
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
  local out
  out=$(git branch --all --sort=committerdate --color | grep -v HEAD | sed 's/.* //' | sed 's/remotes\///' |
    _fzf_run --reverse -m "$@") || return
  print -rn -- "${(j: :)${(@qf)out}} "
}

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
  # -z で空白を含むパスと名前の変更 (R) も 1 要素にする。--short なのでパスはカレントディレクトリからの相対のまま
  local out
  out=$(git status --short -z | fzf_git_status_lines |
    _fzf_run '' -m "$@" --preview 'git diff --color -- "$(print -r -- {} | cut -c4-)"') || return
  print -r -- "$out" | fzf_status_paths
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
  local out
  out=$(git log --oneline --decorate | nl | _fzf_run --reverse "$@" --preview 'git log --numstat --color {2}') || return
  print -rn -- "git rebase -i HEAD~$(print -r -- "$out" | fzf_fields 1)"
}

# 廃止された hub の代わりに gh を使う。3 列目がブランチ名の形式は hub 時代と同じ (docs/adr/0010)。
# (次の行はコマンド選択に出す説明。docs/adr/0033)
# プルリクエストを選び、ブランチ名を入力行に足す
__gh_pr_branch() {
  local out
  out=$(gh pr list --limit 50 --json number,author,headRefName,state,title \
    --jq '.[] | "#\(.number) \(.author.login) \(.headRefName) \(.state) \(.title)"' | _fzf_run --reverse "$@") || return
  print -r -- "$out" | fzf_fields 3
}

# コミットを選び、ハッシュを入力行に足す
__git_log_oneline_commit_hash() {
  local out
  out=$(git log --oneline --decorate | nl | _fzf_run --reverse -m "$@" --preview 'git log --numstat --color {2}') || return
  print -r -- "$out" | fzf_fields 2
}

# コミットを選び、HEAD からの番号を入力行に足す
__git_log_oneline_commit_number() {
  local out
  out=$(git log --oneline --decorate | nl | _fzf_run --reverse -m "$@" --preview 'git log --numstat --color {2}') || return
  print -r -- "$out" | fzf_fields 1
}

# docker のコンテナを選び、ID を入力行に足す
__docker_container_id() {
  local out
  out=$(docker ps | _fzf_run --reverse -m "$@") || return
  print -r -- "$out" | fzf_fields 1
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
  local out
  out=$(docker images | _fzf_run --reverse -m "$@") || return
  print -r -- "$out" | fzf_fields 3
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
  # Yarn 4 (Berry) の一覧。v1 の `yarn workspaces info` は無い (docs/adr/0045)
  yarn workspaces list --json | jq -r .name | fzf
}

# tmux の全セッションのウィンドウを選んで切り替える。入力行には何も足さない
__ftmux_window() {
  [[ -n ${TMUX-} ]] || return 0
  # 処理は tmux の Ctrl-T (ポップアップ) と同じスクリプト (docs/adr/0052)
  $DOTFILES/tmux/scripts/window-switcher "$(tmux display-message -p -t "${TMUX_PANE-}" '#{session_name}:#{window_index}')"
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
  cmd=$(fzf_command_names | _fzf_run --reverse +m | awk '{print $1}')
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
export FZF_DEFAULT_OPTS="--ansi --cycle" # --extended は fzf の既定 (docs/adr/0046)
# ファイル検索は fd (macOS の BSD find は引数なしで失敗する。docs/adr/0002 参照)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# Ctrl-P (fzf-file-widget。fzf 本体の Ctrl-T の機能) でファイルの先頭をプレビューする。独自のコマンドにはこの変数を渡さない (docs/adr/0034)
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
