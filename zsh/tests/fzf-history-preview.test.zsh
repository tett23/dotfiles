#!/usr/bin/env zsh
# zsh/fzf.sh の FZF_CTRL_R_OPTS (Ctrl-R の履歴検索のプレビュー) のテスト (docs/adr/0057)。
# 使い方: zsh zsh/tests/fzf-history-preview.test.zsh
emulate -L zsh
setopt no_unset

local root=${0:A:h:h:h}
source $root/zsh/fzf.sh

local -i failures=0
check() {
  if [[ $2 == $3 ]]; then print -r -- "PASS $1"; else print -r -- "FAIL $1 expected=[$3] actual=[$2]"; (( failures++ )); fi
}

# FZF_CTRL_R_OPTS から、--preview と --bind の値を取り出す
local -a opts=(${(Q)${(z)FZF_CTRL_R_OPTS}})
local preview='' bind=''
local -i i
for (( i = 1; i < $#opts; i++ )); do
  [[ ${opts[i]} == --preview ]] && preview=${opts[i+1]}
  [[ ${opts[i]} == --bind ]] && bind=${opts[i+1]}
done
check "プレビューのコマンドがある" "${${preview:+yes}:-no}" "yes"
check "プレビューの表示は Ctrl-O で切り替える" "$bind" "ctrl-o:toggle-preview"

# bat は、入力をそのまま出す偽物に置き換える (色付けはテストしない)
local tmp=$(mktemp -d)
print -r -- $'#!/bin/sh\ncat' > $tmp/bat
chmod +x $tmp/bat

# fzf と同じく、{} を候補を引用したものに置き換えて sh で実行する
run_preview() {
  local item=$1
  PATH=$tmp:$PATH sh -c "${preview//\{\}/${(qq)item}}"
}

check "番号とタブを外す" "$(run_preview $'123\tgit status')" "git status"
check "番号に * が付いた候補 (編集した履歴)" "$(run_preview $'45*\tls -la')" "ls -la"
check "複数行のコマンドは、続きの行の先頭のタブを外して元の行に戻す" \
  "$(run_preview $'7\tfor f in *; do\n\t  echo $f\n\tdone')" $'for f in *; do\n  echo $f\ndone'
check "コマンドの中のタブは残す" "$(run_preview $'8\tprintf \'a\tb\'')" $'printf \'a\tb\''
check "引用符を含むコマンド" "$(run_preview $'9\techo "it\'s"')" $'echo "it\'s"'

rm -rf $tmp
print
(( failures > 0 )) && { print "$failures failed"; exit 1 }
print "all passed"
