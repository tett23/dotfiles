#!/usr/bin/env zsh
# tmux/scripts/window-switcher が、TMUX の指すサーバーと違うサーバーにつながったときに、一覧を出さずに知らせるかのテスト (docs/adr/0076)。
# 使い方: zsh zsh/tests/window-switcher.test.zsh
emulate -L zsh
setopt no_unset

local root=${0:A:h:h:h}
if ! (( $+commands[tmux] )); then
  print "SKIP tmux が無い"
  exit 0
fi

local -i failures=0
check() {
  if [[ $2 == $3 ]]; then print -r -- "PASS $1"; else print -r -- "FAIL $1 expected=[$3] actual=[$2]"; (( failures++ )); fi
}

# ソケットのパスは短くする (UNIX ドメインソケットのパスの長さの上限)
local work=$(mktemp -d /tmp/wst.XXXXXX)
local sock1=$work/a sock2=$work/b
trap "tmux -S ${(q)sock1} kill-server 2>/dev/null; tmux -S ${(q)sock2} kill-server 2>/dev/null; command rm -rf -- ${(q)work}" EXIT
tmux -S $sock1 -f /dev/null new-session -d -s one
tmux -S $sock2 -f /dev/null new-session -d -s two
local pid1=$(tmux -S $sock1 display-message -p '#{pid}')
local pid2=$(tmux -S $sock2 display-message -p '#{pid}')

# 偽の fzf: 呼ばれたことを記録し、何も選ばずに終わる
mkdir $work/bin
print -r -- '#!/bin/sh
cat > /dev/null
echo called >> "$FZF_CALLED"
exit 1' > $work/bin/fzf
chmod +x $work/bin/fzf

run() {
  local tmux_env=$1
  : > $work/called
  TMUX=$tmux_env FZF_CALLED=$work/called PATH=$work/bin:$PATH \
    sh $root/tmux/scripts/window-switcher 'one:0' < /dev/null > $work/out 2>&1
  print -r -- "$?"
}

check "TMUX が正しいサーバーを指すときは fzf を呼ぶ" "$(run "$sock1,$pid1,0"):$(<$work/called)" "0:called"

local rc=$(run "$sock1,$pid2,0")
check "TMUX の pid と、つながったサーバーの pid が違うときは 0 以外で終わる" "${rc:#0}" "$rc"
check "そのときは fzf を呼ばない" "$(<$work/called)" ""
check "そのときはソケットが置き換わっていることを出す" "${${(M)$(<$work/out):#*置き換わ*}:+yes}" "yes"

print
(( failures > 0 )) && { print "$failures failed"; exit 1 }
print "all passed"
