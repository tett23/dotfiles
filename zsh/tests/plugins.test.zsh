#!/usr/bin/env zsh
# zsh/plugins.sh が、zinit 本体が固定のコミットのときだけ読み込むことのテスト (docs/adr/0142)。
# 使い方: zsh zsh/tests/plugins.test.zsh
# 取得元と固定のコミットは、plugins.sh の写しの _zinit_url と _zinit_rev の行を書き換えて差し替える
emulate -L zsh
setopt no_unset

local root=${0:A:h:h:h}
local work=$(mktemp -d "${TMPDIR:-/tmp}/plugins-test.XXXXXX")
trap "command rm -rf -- ${(q)work}" EXIT

local -i failures=0
check() {
  if [[ $2 == $3 ]]; then print -r -- "PASS $1"; else print -r -- "FAIL $1 expected=${(q+)3} actual=${(q+)2}"; (( failures++ )); fi
}

# 偽の zinit のリポジトリ。zinit.zsh は zinit 関数を定義するだけ
local src=$work/src
git init -q $src
print -r -- 'zinit() { :; }' > $src/zinit.zsh
git -C $src add zinit.zsh
git -C $src -c user.name=t -c user.email=t@example.com commit -qm first
local first=$(git -C $src rev-parse HEAD)
print -r -- '# second' >> $src/zinit.zsh
git -C $src -c user.name=t -c user.email=t@example.com commit -qam second
local second=$(git -C $src rev-parse HEAD)
local absent=0123456789abcdef0123456789abcdef01234567

# plugins.sh の写しを、取得元 $1、固定のコミット $2 で作り、新しい zsh で読む。zinit が定義されたかを返す
run_plugins() {
  local url=$1 rev=$2
  sed -e "s|^typeset -g _zinit_url=.*|typeset -g _zinit_url=$url|" \
      -e "s|^typeset -g _zinit_rev=.*|typeset -g _zinit_rev=$rev|" \
      $root/zsh/plugins.sh > $work/plugins.sh
  XDG_DATA_HOME=$work/data zsh -fc "source $work/plugins.sh >/dev/null 2>&1; print \${+functions[zinit]}"
}

fresh() { command rm -rf -- $work/data }

# I1: HEAD が _zinit_rev と違い、_zinit_rev を持たない
fresh
git clone -q $src $work/data/zinit/zinit.git
check "ADR 0142 I1: HEAD が固定のコミットと違い、そのコミットを持たないときは読み込まない" "$(run_plugins $src $absent)" 0

# I1: clone が失敗する
fresh
check "ADR 0142 I1: clone が失敗したときは読み込まない" "$(run_plugins $work/no-such-repo $first)" 0

# I2: clone した HEAD が _zinit_rev
fresh
check "ADR 0142 I2: clone した HEAD が固定のコミットなら読み込む" "$(run_plugins $src $second)" 1

# I2: HEAD が違っても、固定のコミットに切り替えられれば読み込む
fresh
git clone -q $src $work/data/zinit/zinit.git
check "ADR 0142 I2: 固定のコミットに切り替えられれば読み込む" "$(run_plugins $src $first)" 1
check "ADR 0142 I2: 切り替えた後の HEAD は固定のコミット" "$(git -C $work/data/zinit/zinit.git rev-parse HEAD)" $first

(( failures == 0 ))
