#!/usr/bin/env zsh
# zsh/lib/gitignore-completion.zsh の __gitignored_names のテスト (docs/adr/0038)。
# 使い方: zsh zsh/tests/gitignore-completion.test.zsh
emulate -L zsh
setopt no_unset

local root=${0:A:h:h:h}
source $root/zsh/lib/gitignore-completion.zsh

local work=$(mktemp -d "${TMPDIR:-/tmp}/gitignore-completion-test.XXXXXX")
trap "command rm -r -- ${(q)work}" EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

local -i failures=0
check() {
  if [[ $2 == $3 ]]; then print -r -- "PASS $1"; else print -r -- "FAIL $1 expected=[$3] actual=[$2]"; (( failures++ )); fi
}
names() { print -r -- "${(j: :)${(@o)${(@f)$(__gitignored_names $1)}}}" }

# リポジトリ: .gitignore で .cache/・secret.txt・node_modules/ を除外し、src/.gitignore で build/ を除外する
local repo=$work/repo
mkdir -p $repo/{.github,.cache,node_modules/pkg,src/build,src/lib}
touch $repo/{.env.example,secret.txt,tracked.txt} $repo/.github/ci.yml $repo/.cache/x $repo/node_modules/pkg/index.js
touch $repo/src/main.ts $repo/src/build/out.js $repo/src/lib/a.ts
print -l '.cache/' 'secret.txt' 'node_modules/' > $repo/.gitignore
print -l 'build/' > $repo/src/.gitignore
git -C $repo init -q
git -C $repo add tracked.txt .gitignore

check "ルートでは .gitignore で除外した名前だけを出す" "$(names $repo)" ".cache node_modules secret.txt"
check "サブディレクトリでは直下の名前を出し、ネストした .gitignore も効く" "$(names $repo/src)" "build"
check "無視されるものが無いディレクトリでは何も出さない" "$(names $repo/.github)" ""

mkdir -p $work/plain/.hidden
check "git のリポジトリの外では何も出さない" "$(names $work/plain)" ""
check "存在しないディレクトリでは何も出さない" "$(names $work/missing)" ""

print
(( failures > 0 )) && { print "$failures failed"; exit 1 }
print "all passed"
