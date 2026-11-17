#!/usr/bin/env zsh
# bin/update-nix の取得元の確かめと、適用の前の確認のテスト (docs/adr/0139)。使い方: zsh zsh/tests/update-nix.test.zsh
# curl、nix、sudo、darwin-rebuild は PATH の先頭に置いた偽のコマンドで置き換え、呼ばれた引数をファイルに記録する。
# 偽の curl は、URL の / を _ にした名前のファイルを $FAKE_HTTP から返し、無ければ失敗する
emulate -L zsh
setopt no_unset

local root=${0:A:h:h:h}
local un=$root/bin/update-nix
if (( ! $+commands[bash] || ! $+commands[git] || ! $+commands[jq] )); then
  print "SKIP bash か git か jq がありません"
  exit 0
fi

local work=$(mktemp -d "${TMPDIR:-/tmp}/update-nix-test.XXXXXX")
trap "command rm -rf -- ${(q)work}" EXIT

mkdir -p $work/bin
local cmd
for cmd in sudo darwin-rebuild; do
  print -r -- "#!/bin/sh
printf '%s\n' \"$cmd \$*\" >> \"\$FAKE_LOG\"
exit 0" > $work/bin/$cmd
done
# 偽の nix。flake update のときは、FAKE_FLAKE_CHANGE があれば flake.lock を書き換える
cat > $work/bin/nix <<'EOF2'
#!/bin/sh
printf '%s\n' "nix $*" >> "$FAKE_LOG"
if [ "$1 $2" = "flake update" ] && [ -n "${FAKE_FLAKE_CHANGE:-}" ]; then
  printf '%s\n' '{"changed":true}' > "$DOTFILES/flake.lock"
fi
exit 0
EOF2
cat > $work/bin/curl <<'EOF2'
#!/bin/sh
for a in "$@"; do url=$a; done
printf '%s\n' "curl $url" >> "$FAKE_LOG"
f="$FAKE_HTTP/$(printf '%s' "$url" | tr '/' '_')"
[ -f "$f" ] || exit 22
cat "$f"
EOF2
chmod +x $work/bin/*

local -i failures=0
check() {
  if [[ $2 == $3 ]]; then print -r -- "PASS $1"; else print -r -- "FAIL $1 expected=${(q+)3} actual=${(q+)2}"; (( failures++ )); fi
}

local claude_url=https://downloads.claude.ai/releases/darwin/universal/5.1231.2/Claude-26912242b6649f3e503e012d9b7b9367d09c68e4.zip
local claude_sha=e74cfec98d2560812a5fe91bb07fe4a277cefea71d4039f6bf3b1de33846240a
local aqua_url=https://github.com/codefirst/aquaskk/releases/download/4.7.9/AquaSKK-4.7.9.pkg
local aqua_sha=1111111111111111111111111111111111111111111111111111111111111111
local other_sha=2222222222222222222222222222222222222222222222222222222222222222

local dot http code out
# DOTFILES の写しと、既定の応答 (claude は版が同じ、aquaskk は 4.7.9 に上がり digest が一致) を作る
setup() {
  dot=$(mktemp -d $work/dot.XXXXXX)
  http=$dot.http
  mkdir -p $dot/nix/pkgs $http $dot.tmp
  print '{ }' > $dot/flake.nix
  print '{}' > $dot/flake.lock
  cp $root/nix/pkgs/sources.json $dot/nix/pkgs/sources.json
  git -C $dot init -q
  git -C $dot add -A
  git -C $dot -c user.name=t -c user.email=t@example.invalid commit -q -m init
  : > $dot.log
  print -n > $dot.answer
  brew claude 5.1231.2 $claude_url $claude_sha
  brew aquaskk 4.7.9 $aqua_url $aqua_sha
  release 4.7.9 AquaSKK-4.7.9.pkg "\"sha256:$aqua_sha\""
}
# Homebrew の cask の応答を置く
brew() {
  jq -n --arg v $2 --arg u $3 --arg s $4 '{version: $v, url: $u, sha256: $s}' \
    > $http/${${:-https://formulae.brew.sh/api/cask/$1.json}//\//_}
}
# GitHub のリリースの応答を置く。$3 は digest の JSON の値
release() {
  print -r -- "{\"tag_name\":\"$1\",\"assets\":[{\"name\":\"$2\",\"digest\":$3}]}" \
    > $http/${${:-https://api.github.com/repos/codefirst/aquaskk/releases/tags/$1}//\//_}
}
# update-nix を動かす。答えは $dot.answer から読ませる
run_un() {
  out=$(cd $dot && PATH=$work/bin:$PATH DOTFILES=$dot TMPDIR=$dot.tmp FAKE_LOG=$dot.log FAKE_HTTP=$http \
    UPDATE_NIX_TTY=${TTY_FILE:-$dot.answer} bash $un "$@" 2>&1 </dev/null); code=$?
}
unchanged() { git -C $dot diff --quiet HEAD && print 1 || print 0 }
called() { grep -c "^$1" $dot.log }
# 確認の問いに断られて止まったか (確かめの失敗で止まったのではないこと)
refused() { print -r -- $out | grep -c "適用しませんでした" }

# I1: aquaskk の url が許す接頭辞の外
for bad in https://evil.example/AquaSKK.pkg https://github.com/someone/aquaskk/releases/download/4.7.9/AquaSKK-4.7.9.pkg; do
  setup; print y > $dot.answer
  brew aquaskk 4.7.9 $bad $aqua_sha
  run_un
  check "ADR 0139 I1: 接頭辞の外の url ($bad) では何も変えず 1" "$code|$(unchanged)|$(called nix)|$(called sudo)" "1|1|0|0"
done

# I1: claude の版が上がっても、aquaskk の url が接頭辞の外なら claude の分も書かない
setup; print y > $dot.answer
brew claude 5.2000.0 https://downloads.claude.ai/releases/darwin/universal/5.2000.0/Claude.zip $other_sha
brew aquaskk 4.7.9 https://evil.example/AquaSKK.pkg $aqua_sha
run_un
check "ADR 0139 I1: ほかのパッケージの分も書かずに 1" "$code|$(unchanged)|$(called nix)|$(called sudo)" "1|1|0|0"

# I2: digest が別のハッシュ
setup; print y > $dot.answer
release 4.7.9 AquaSKK-4.7.9.pkg "\"sha256:$other_sha\""
run_un
check "ADR 0139 I2: digest が違えば何も変えず 1" "$code|$(unchanged)|$(called nix)|$(called sudo)" "1|1|0|0"

# I6: digest が null
setup; print y > $dot.answer
release 4.7.9 AquaSKK-4.7.9.pkg null
run_un
check "ADR 0139 I6: digest が null なら警告を出して続ける" "$code|$(called 'sudo darwin-rebuild switch')" "0|1"
check "ADR 0139 I6: digest が null の警告" "$(print -r -- $out | grep -c 'GitHub のリリースにハッシュがありません')" 1

# I7: GitHub の API が失敗する
setup; print y > $dot.answer
command rm -f $http/*api.github.com*
run_un
check "ADR 0139 I7: GitHub の API を読めなければ何も変えず 1" "$code|$(unchanged)|$(called nix)|$(called sudo)" "1|1|0|0"

# I8: 版が変わらず、flake.lock も変わらない
setup; print y > $dot.answer
brew aquaskk 4.7.3 https://github.com/codefirst/aquaskk/releases/download/4.7.3/AquaSKK-4.7.3.pkg \
  bf3300ceb8f5fd2433e244de0f43f1962073b5048f1536ef58e617f7c4785abd
release 4.7.3 AquaSKK-4.7.3.pkg null
run_un
check "ADR 0139 I8: 差分が無ければビルドも確認もせず 0" "$code|$(called 'nix build')|$(called sudo)|$(print -r -- $out | grep -c '適用しますか')" "0|0|0|0"
check "ADR 0139 I8: 差分が無いと出す" "$(print -r -- $out | grep -c '差分はありません')" 1

# I8: 実行の前からの未コミットの変更は差分に出ない
setup; print y > $dot.answer
brew aquaskk 4.7.3 https://github.com/codefirst/aquaskk/releases/download/4.7.3/AquaSKK-4.7.3.pkg \
  bf3300ceb8f5fd2433e244de0f43f1962073b5048f1536ef58e617f7c4785abd
release 4.7.3 AquaSKK-4.7.3.pkg null
jq '.["claude-desktop"].sha256 = "edited"' $dot/nix/pkgs/sources.json > $dot.json && mv $dot.json $dot/nix/pkgs/sources.json
run_un
check "ADR 0139 I8: 前からの変更だけなら差分なしとして 0" "$code|$(called 'nix build')|$(called sudo)" "0|0|0"

# I4, I5: digest が一致し、答え y
setup; print y > $dot.answer
FAKE_FLAKE_CHANGE=1 run_un
check "ADR 0139 I4, I5: 答え y で一度だけ適用する" "$code|$(called 'sudo darwin-rebuild switch')" "0|1"
local diff_line=$(print -r -- $out | grep -n '^+.*"version": "4.7.9"' | head -1 | cut -d: -f1)
local lock_line=$(print -r -- $out | grep -n '^+{"changed":true}' | head -1 | cut -d: -f1)
local ask_line=$(print -r -- $out | grep -n '適用しますか' | head -1 | cut -d: -f1)
check "ADR 0139 I4: sources.json と flake.lock の差分が問いより前に出る" \
  "$(( ${diff_line:-999} < ${ask_line:-0} && ${lock_line:-999} < ${ask_line:-0} ))" 1
check "ADR 0139 I4: sources.json は新しい版になる" "$(jq -r '.aquaskk.version' $dot/nix/pkgs/sources.json)" 4.7.9

# I5: 答え YES
setup; print YES > $dot.answer
run_un
check "ADR 0139 I5: 答え YES で適用する" "$code|$(called 'sudo darwin-rebuild switch')" "0|1"

# I3: y か yes 以外の答え
local ans
for ans in n '' yy; do
  setup; print -r -- "$ans" > $dot.answer
  run_un
  check "ADR 0139 I3: 答え '${ans}' では適用せず 1" "$code|$(called sudo)|$(called darwin-rebuild)|$(refused)" "1|0|0|1"
done
setup
TTY_FILE=$dot.nofile run_un
check "ADR 0139 I3: UPDATE_NIX_TTY が無いファイルなら適用せず 1" "$code|$(called sudo)|$(refused)" "1|0|1"

# I3: 答えを標準入力にだけ流す
setup; : > $dot.answer
out=$(cd $dot && print y | PATH=$work/bin:$PATH DOTFILES=$dot TMPDIR=$dot.tmp FAKE_LOG=$dot.log FAKE_HTTP=$http \
  UPDATE_NIX_TTY=$dot.answer bash $un 2>&1); code=$?
check "ADR 0139 I3: 標準入力の y では適用せず 1" "$code|$(called sudo)|$(refused)" "1|0|1"


(( failures == 0 ))
