#!/usr/bin/env zsh
# bin/sync-deps の --switch の確認のテスト (docs/adr/0133)。使い方: zsh zsh/tests/sync-deps.test.zsh
# claude、nix、sudo、darwin-rebuild、mise は PATH の先頭に置いた偽のコマンドで置き換え、呼ばれた引数をファイルに記録する。
# 偽の claude は、環境変数 FAKE_CLAUDE のシェルの断片を DOTFILES の中で動かす
emulate -L zsh
setopt no_unset

local root=${0:A:h:h:h}
local sd=$root/bin/sync-deps
if (( ! $+commands[bash] || ! $+commands[git] )); then
  print "SKIP bash か git がありません"
  exit 0
fi

local work=$(mktemp -d "${TMPDIR:-/tmp}/sync-deps-test.XXXXXX")
trap "command rm -rf -- ${(q)work}" EXIT

mkdir -p $work/bin
local cmd
for cmd in nix sudo darwin-rebuild mise; do
  print -r -- "#!/bin/sh
printf '%s\n' \"$cmd \$*\" >> \"\$FAKE_LOG\"
exit 0" > $work/bin/$cmd
done
cat > $work/bin/claude <<'EOF'
#!/usr/bin/env zsh
printf '%s\n' "claude" >> "$FAKE_LOG"
eval "${FAKE_CLAUDE:-:}"
EOF
chmod +x $work/bin/*

local -i failures=0
check() {
  if [[ $2 == $3 ]]; then print -r -- "PASS $1"; else print -r -- "FAIL $1 expected=${(q+)3} actual=${(q+)2}"; (( failures++ )); fi
}

local dot tmp code out
# DOTFILES の写しを作る
setup() {
  dot=$(mktemp -d $work/dot.XXXXXX)
  tmp=$dot.tmp
  mkdir -p $tmp $dot/mise $dot/nix
  print '# deps' > $dot/dependencies.md
  print '{ }' > $dot/flake.nix
  print '{}' > $dot/flake.lock
  print '[tools]' > $dot/mise/config.toml
  print 'pkg' > $dot/nix/a.nix
  print 'keep' > $dot/other.md
  print 'ignored.txt' > $dot/.gitignore
  git -C $dot init -q
  git -C $dot add -A
  git -C $dot -c user.name=t -c user.email=t@example.invalid commit -q -m init
  : > $dot.log
  print -n > $dot.answer
}
# sync-deps を動かす。引数は sync-deps の引数。答えは $dot.answer から読ませる
run_sd() {
  out=$(cd $dot && PATH=$work/bin:$PATH DOTFILES=$dot TMPDIR=$tmp FAKE_LOG=$dot.log FAKE_CLAUDE=${FAKE_CLAUDE:-:} \
    SYNC_DEPS_TTY=${TTY_FILE:-$dot.answer} bash $sd "$@" 2>&1 </dev/null); code=$?
}
applied() { grep -c -E '^(sudo|darwin-rebuild|mise install)' $dot.log }
asked() { [[ $out == *'適用しますか? [y/N]'* ]] && print yes || print no }
local add_line='print "# added" >> flake.nix'

# I2, I5: 答え y で適用する
setup; print y > $dot.answer
FAKE_CLAUDE=$add_line run_sd --switch
check "ADR 0133 I5: --switch、差分あり、答え y なら適用する" "$code|$(grep -c '^sudo darwin-rebuild switch' $dot.log)|$(grep -c '^mise install' $dot.log)" "0|1|1"
local before_q=${out%%適用しますか*}
check "ADR 0133 I2: 答えを読む前に差分の全体 (足した行) を出す" "$([[ $before_q == *'+# added'* ]] && print yes)" "yes"

setup; print YES > $dot.answer
FAKE_CLAUDE=$add_line run_sd --switch
check "ADR 0133 I5: 答え YES なら適用する" "$code|$(grep -c '^sudo darwin-rebuild switch' $dot.log)" "0|1"

# I1: 適用しない答え
local ans
for ans in n '' yy; do
  setup; print -r -- "$ans" > $dot.answer
  FAKE_CLAUDE=$add_line run_sd --switch
  check "ADR 0133 I1: 答え ${(q+)ans} なら適用せず 1" "$code|$(applied)|$(asked)|$([[ $out == *適用しませんでした* ]] && print y)" "1|0|yes|y"
done
setup
FAKE_CLAUDE=$add_line TTY_FILE=$dot.nofile run_sd --switch
check "ADR 0133 I1: SYNC_DEPS_TTY が無いファイルなら適用せず 1" "$code|$(applied)" "1|0"
setup; : > $dot.answer
out=$(cd $dot && print y | PATH=$work/bin:$PATH DOTFILES=$dot TMPDIR=$tmp FAKE_LOG=$dot.log FAKE_CLAUDE=$add_line \
  SYNC_DEPS_TTY=$dot.answer bash $sd --switch 2>&1); code=$?
check "ADR 0133 I1: 答え y を標準入力にだけ流しても適用せず 1" "$code|$(applied)" "1|0"

# I3: --switch なし
setup; print y > $dot.answer
FAKE_CLAUDE=$add_line run_sd
check "ADR 0133 I3: --switch なしでは答えを読まず、適用しない" "$code|$(applied)|$(asked)" "0|0|no"
check "ADR 0133 I3: --switch なしでも差分の全体を出す" "$([[ $out == *'+# added'* ]] && print yes)" "yes"

# I4: 差分なし
setup; print y > $dot.answer
run_sd --switch
check "ADR 0133 I4: 差分が無ければ答えを読まず、適用しない" "$code|$(applied)|$(asked)" "0|0|no"

# I6: TARGETS の外の変更
setup; print y > $dot.answer
FAKE_CLAUDE='print "{ }" > x.nix; git add -N x.nix; print "# import ./x.nix" >> flake.nix' run_sd --switch
check "ADR 0133 I6: TARGETS の外に x.nix を作ると、そのパスを出し、答えを読まず、適用せず 1" \
  "$code|$(applied)|$(asked)|$([[ $out == *x.nix* ]] && print y)" "1|0|no|y"
setup; print y > $dot.answer
FAKE_CLAUDE='rm other.md; print "# added" >> flake.nix' run_sd --switch
check "ADR 0133 I6: TARGETS の外の追跡しているファイルを消すと、適用せず 1" "$code|$(applied)|$([[ $out == *other.md* ]] && print y)" "1|0|y"
setup; print y > $dot.answer
FAKE_CLAUDE='print changed >> other.md; print "# added" >> flake.nix' run_sd
check "ADR 0133 I6: --switch が無くても、TARGETS の外を変えると 1" "$code|$([[ $out == *other.md* ]] && print y)" "1|y"
setup; print y > $dot.answer
FAKE_CLAUDE='print x > ignored.txt; print "# added" >> flake.nix' run_sd --switch
check "ADR 0133 I6: .gitignore で除いたファイルだけを作るのは止めない" "$code|$(applied)" "0|2"
setup; print y > $dot.answer
FAKE_CLAUDE='print "pkg2" > nix/b.nix; git add -N nix/b.nix' run_sd --switch
check "ADR 0133 I6: TARGETS の中の nix/ に足したファイルは止めない" "$code|$(applied)" "0|2"

# I7: 生成の前の写しの書き換え
setup; print y > $dot.answer
FAKE_CLAUDE='s=$(ls -d "$TMPDIR"/sync-deps.* | head -1); print "# added" >> flake.nix; cp flake.nix "$s/flake.nix"' run_sd --switch
check "ADR 0133 I7: 生成の前の写しを書き換えると、差分を見せず、答えを読まず、適用せず 1" \
  "$code|$(applied)|$(asked)|$([[ $out == *'生成の前の写しが変わりました'* ]] && print y)|$([[ $out == *'+# added'* ]] && print shown || print hidden)" \
  "1|0|no|y|hidden"

print
(( failures > 0 )) && { print "$failures failed"; exit 1 }
print "all passed"
