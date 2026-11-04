#!/usr/bin/env zsh
# zsh/lib/tmux-osc7.zsh のテスト (docs/adr/0085)。使い方: zsh zsh/tests/tmux-osc7.test.zsh
emulate -L zsh
setopt no_unset

local root=${0:A:h:h:h}
local work=$(mktemp -d "${TMPDIR:-/tmp}/tmux-osc7-test.XXXXXX")
trap "command rm -r -- ${(q)work}" EXIT
source $root/zsh/lib/tmux-osc7.zsh
# 動きを確かめる間は hook を外し、関数を直接呼ぶ (テスト自身の cd で書かないように)
add-zsh-hook -d precmd _tmux_osc7_report
add-zsh-hook -d chpwd _tmux_osc7_report

local -i failures=0
check() {
  if [[ $2 == $3 ]]; then print -r -- "PASS $1"; else print -r -- "FAIL $1 expected=${(q+)3} actual=${(q+)2}"; (( failures++ )); fi
}

check "OSC 7 を tmux の passthrough で包む" \
  "$(tmux_osc7_sequence dione4.local /Users/a/b)" \
  $'\ePtmux;\e\e]7;kitty-shell-cwd://dione4.local/Users/a/b\a\e\\'
check "空白と日本語はそのまま入る" \
  "$(tmux_osc7_sequence dione4.local '/Users/a/日本 語')" \
  $'\ePtmux;\e\e]7;kitty-shell-cwd://dione4.local/Users/a/日本 語\a\e\\'
check "ホストとパスの制御文字を取り除く" \
  "$(tmux_osc7_sequence $'dio\ene4' $'/Users/a\a/b\e')" \
  $'\ePtmux;\e\e]7;kitty-shell-cwd://dione4/Users/a/b\a\e\\'

# 書き込み先を作業用のファイルに差し替える
_tmux_osc7_out=$work/out
TMUX=/tmp/tmux-501/default,1,0
: > $work/out; _tmux_osc7_report
check "tmux の中では今のディレクトリを書く" "$(<$work/out)" "$(tmux_osc7_sequence $HOST $PWD)"
TMUX=
: > $work/out; _tmux_osc7_report
check "tmux の外では何も書かない" "$(<$work/out)" ""

# 2 回読み込んでも、hook には 1 回だけ登録する
source $root/zsh/lib/tmux-osc7.zsh
source $root/zsh/lib/tmux-osc7.zsh
check "precmd に 1 回だけ登録する" "${#${(@M)precmd_functions:#_tmux_osc7_report}}" "1"
check "chpwd に 1 回だけ登録する" "${#${(@M)chpwd_functions:#_tmux_osc7_report}}" "1"

print
(( failures > 0 )) && { print "$failures failed"; exit 1 }
print "all passed"
