#!/usr/bin/env zsh
# zsh/lib/command-time.zsh のテスト (docs/adr/0083)。使い方: zsh zsh/tests/command-time.test.zsh
emulate -L zsh
setopt no_unset

local root=${0:A:h:h:h}
source $root/zsh/lib/command-time.zsh
# zsh はスクリプトの中でもコマンドごとに preexec を呼ぶので、動きを確かめる間は hook を外し、関数を直接呼ぶ
add-zsh-hook -d preexec _command_time_preexec
add-zsh-hook -d precmd _command_time_precmd
unset _command_time_start # 外すまでのコマンドで、preexec が開始の時刻を覚えている

local -i failures=0
check() {
  if [[ $2 == $3 ]]; then print -r -- "PASS $1"; else print -r -- "FAIL $1 expected=${(q+)3} actual=${(q+)2}"; (( failures++ )); fi
}

check "0 秒" "$(command_time_format 0)" "0h:00m:00s"
check "5 秒" "$(command_time_format 5)" "0h:00m:05s"
check "65 秒" "$(command_time_format 65)" "0h:01m:05s"
check "3725 秒" "$(command_time_format 3725)" "1h:02m:05s"

# コマンドを実行し (preexec)、$elapsed 秒たった後のプロンプトの前 (precmd) の出力
run_command() {
  local elapsed=$1
  SECONDS=100
  _command_time_preexec "sleep $elapsed"
  SECONDS=$(( 100 + elapsed ))
  _command_time_precmd
}

local expected=$(print -P "%F{white}Time: 0h:00m:03s%f")
TTY=/dev/ttys000
check "端末で 3 秒以上なら出す" "$(run_command 3)" "$expected"
check "2 秒なら出さない" "$(run_command 2)" ""
TTY=
check "端末でなければ出さない" "$(run_command 3)" ""

TTY=/dev/ttys000
# 空の行で Enter を押したとき (preexec が呼ばれない)
check "コマンドを実行していなければ出さない" "$(SECONDS=100; _command_time_precmd)" ""
check "出した後の precmd では出さない" "$(run_command 3 >/dev/null; SECONDS=200; _command_time_precmd)" ""

# 2 回読み込んでも、hook には 1 回だけ登録する
source $root/zsh/lib/command-time.zsh
source $root/zsh/lib/command-time.zsh
check "preexec に 1 回だけ登録する" "${#${(@M)preexec_functions:#_command_time_preexec}}" "1"
check "precmd に 1 回だけ登録する" "${#${(@M)precmd_functions:#_command_time_precmd}}" "1"

print
(( failures > 0 )) && { print "$failures failed"; exit 1 }
print "all passed"
