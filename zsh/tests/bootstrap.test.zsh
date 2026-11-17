#!/usr/bin/env zsh
# bootstrap.sh の Nix のインストーラーのハッシュの確かめのテスト (docs/adr/0141)。使い方: zsh zsh/tests/bootstrap.test.zsh
# bootstrap.sh の写しの NIX_INSTALLER_SHA256 を偽のインストーラーのハッシュに書き換え、source して ensure_nix を呼ぶ。
# curl は PATH の先頭の偽のコマンドで置き換え、FAKE_BODY のファイルを -o の先に写す (FAKE_BODY が無ければ失敗する)。
# PATH には /usr/bin と /bin だけを足し、本物の nix を見えなくする
emulate -L zsh
setopt no_unset

local root=${0:A:h:h:h}
if (( ! $+commands[bash] || ! $+commands[shasum] )); then
  print "SKIP bash か shasum がありません"
  exit 0
fi

local work=$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-test.XXXXXX")
trap "command rm -rf -- ${(q)work}" EXIT

mkdir -p $work/bin $work/tmp
cat > $work/bin/curl <<'EOF2'
#!/bin/sh
out=""
while [ $# -gt 0 ]; do
  case $1 in
  -o) out=$2; shift ;;
  esac
  shift
done
[ -n "${FAKE_BODY:-}" ] && [ -f "$FAKE_BODY" ] || exit 22
if [ -n "$out" ]; then cat "$FAKE_BODY" > "$out"; else cat "$FAKE_BODY"; fi
EOF2
chmod +x $work/bin/curl

# 偽のインストーラー。引数を記録し、偽の nix を置く
local installer=$work/installer.sh
cat > $installer <<EOF2
#!/bin/sh
printf '%s\n' "installer \$*" >> "\$FAKE_LOG"
printf '#!/bin/sh\necho "nix (fake) 0"\n' > $work/bin/nix
chmod +x $work/bin/nix
EOF2
local sha=$(shasum -a 256 $installer | awk '{print $1}')
sed "s/^NIX_INSTALLER_SHA256=.*/NIX_INSTALLER_SHA256=$sha/" $root/bootstrap.sh > $work/bootstrap.sh

local -i failures=0
check() {
  if [[ $2 == $3 ]]; then print -r -- "PASS $1"; else print -r -- "FAIL $1 expected=${(q+)3} actual=${(q+)2}"; (( failures++ )); fi
}

local code out
# ensure_nix を動かす。$1 は偽の curl が返す中身のファイル (空なら curl が失敗する)
run_ensure() {
  command rm -f $work/bin/nix $work/log
  : > $work/log
  out=$(PATH=$work/bin:/usr/bin:/bin TMPDIR=$work/tmp FAKE_BODY=$1 FAKE_LOG=$work/log \
    bash -c 'source "$1" && load_nix_env() { :; } && ensure_nix' _ $work/bootstrap.sh 2>&1); code=$?
}
ran() { grep -c '^installer' $work/log }

print -r -- 'echo evil' > $work/other.sh
run_ensure $work/other.sh
check "ADR 0141 I1: ハッシュが違う中身は動かさず 1" "$code|$(ran)|$([[ $out == *sha256*違います* ]] && print y)" "1|0|y"

: > $work/empty.sh
run_ensure $work/empty.sh
check "ADR 0141 I1: 空の中身は動かさず 1" "$code|$(ran)|$([[ $out == *sha256*違います* ]] && print y)" "1|0|y"

run_ensure ""
check "ADR 0141 I1: curl が失敗したら動かさず 1" "$code|$(ran)|$([[ $out == *取得できませんでした* ]] && print y)" "1|0|y"

run_ensure $installer
check "ADR 0141 I2: ハッシュが一致すれば install --no-confirm で一度だけ動かす" "$code|$(ran)|$(cat $work/log)" "0|1|installer install --no-confirm"
check "ADR 0141 I2: 一時ファイルを残さない" "$(ls -A $work/tmp | wc -l | tr -d ' ')" 0

(( failures == 0 ))
