#!/usr/bin/env zsh
# zsh/fzf.sh のコマンド選択 (Ctrl-O) の一覧を作る fzf_command_names のテスト (docs/adr/0033)。
# 使い方: zsh zsh/tests/fzf-command-finder.test.zsh
emulate -L zsh
setopt no_unset

local root=${0:A:h:h:h}

local -i failures=0
check() {
  if [[ $2 == $3 ]]; then print -r -- "PASS $1"; else print -r -- "FAIL $1 expected=[$3] actual=[$2]"; (( failures++ )); fi
}

# 別のファイル (このテスト) で定義した __ 付きの関数。fzf 本体の __fzfcmd に相当し、一覧に出てはいけない
__defined_elsewhere() { :; }

bindkey -v
source $root/zsh/fzf.sh

local -a lines=("${(@f)$(fzf_command_names)}")
local -A key desc
local line name
for line in $lines; do
  name=${line%% *}
  # 名前・キー・説明は空白で区切られ、キーの列は 4 文字幅
  key[$name]=${${line[32,35]}// /}
  desc[$name]=${line[37,-1]}
done

# zsh/fzf.sh で定義している __ 付きの関数 (__ を外した名前) を、ファイルから数える
local -a expected=(${(f)"$(grep -oE '^__[A-Za-z0-9_]+ *\(\)' $root/zsh/fzf.sh | sed -E 's/^__([A-Za-z0-9_]+).*/\1/' | sort)"})
check "zsh/fzf.sh の __ 付きの関数がすべて出る" "${(j: :)${(@o)${(@k)key}}}" "${(j: :)expected}"
check "別のファイルの __ 付きの関数は出ない" "${+key[defined_elsewhere]}" "0"
check "fzf_command_names 自身は出ない" "${+key[fzf_command_names]}" "0"
check "ウィンドウの切り替えが出る" "${+key[ftmux_window]}" "1"

check "割り当てたキーを出す (repo)" "${key[repo]-}" "^G"
check "割り当てたキーを出す (ftmux_window)" "${key[ftmux_window]-}" "^T"
check "割り当てが無ければ空欄 (docker_stop_container)" "${key[docker_stop_container]-x}" ""

check "関数の直前のコメントを説明として出す (repo)" "${desc[repo]-}" "ghq のリポジトリを選び、パスを入力行に足す"
for name in ${(k)desc}; do
  [[ -n ${desc[$name]} ]] || check "説明がある ($name)" "" "(説明)"
done

print
(( failures > 0 )) && { print "$failures failed"; exit 1 }
print "all passed"
