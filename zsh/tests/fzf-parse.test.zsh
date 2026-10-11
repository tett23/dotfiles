#!/usr/bin/env zsh
# zsh/fzf.sh の、fzf の入出力を解析する関数のテスト (docs/adr/0046)。
# 使い方: zsh zsh/tests/fzf-parse.test.zsh
emulate -L zsh
setopt no_unset

local root=${0:A:h:h:h}
source $root/zsh/fzf.sh

local -i failures=0
check() {
  if [[ $2 == $3 ]]; then print -r -- "PASS $1"; else print -r -- "FAIL $1 expected=[$3] actual=[$2]"; (( failures++ )); fi
}

# git status --short -z の出力 (NUL 区切り。名前の変更は「変更後のパス」「変更前のパス」の 2 つの要素になる)
local status_z=$' M a.txt\0?? dir with space/b c.txt\0R  new name.txt\0old name.txt\0A  d.txt\0'
check "git status の行: 1 要素 1 行にし、名前の変更は変更後のパスにする" \
  "$(print -rn -- $status_z | fzf_git_status_lines)" \
  $' M a.txt\n?? dir with space/b c.txt\nR  new name.txt\nA  d.txt'
check "git status の行: 空の入力では何も出さない" "$(print -rn -- '' | fzf_git_status_lines)" ""

check "fzf_fields: 各行の n 列目を空白でつなぐ" "$(print -l 'a1 b1 c1' 'a2 b2 c2' | fzf_fields 2)" "b1 b2"
check "fzf_fields: 1 行だけ" "$(print -l '  3  abc1234 message' | fzf_fields 1)" "3"
check "fzf_fields: 空の入力では何も出さない" "$(print -rn -- '' | fzf_fields 1)" ""

check "fzf_status_paths: 状態の 3 文字を外し、引用してつなぐ" \
  "$(print -l ' M a.txt' '?? dir with space/b c.txt' | fzf_status_paths)" \
  'a.txt dir\ with\ space/b\ c.txt'
check "fzf_status_paths: 空の入力では何も出さない" "$(print -rn -- '' | fzf_status_paths)" ""

print
(( failures > 0 )) && { print "$failures failed"; exit 1 }
print "all passed"
