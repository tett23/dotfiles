#!/usr/bin/env zsh
# zsh/lib/cached-eval.zsh のテスト。使い方: zsh zsh/tests/cached-eval.test.zsh
emulate -L zsh
setopt no_unset

local root=${0:A:h:h:h}
local work=$(mktemp -d "${TMPDIR:-/tmp}/cached-eval-test.XXXXXX")
trap "command rm -r -- ${(q)work}" EXIT
export XDG_CACHE_HOME=$work/cache
path=($work/bin $path)
mkdir -p $work/bin
source $root/zsh/lib/cached-eval.zsh

local -i failures=0
check() {
  if [[ $2 == $3 ]]; then print -r -- "PASS $1"; else print -r -- "FAIL $1 expected=$3 actual=$2"; (( failures++ )); fi
}

# 実行回数を数え、読み込まれると VALUE を設定するスクリプトを出力する偽のコマンド
make_fake() {
  print -r -- "#!/bin/sh
echo run >> $work/count
echo 'VALUE=$1'" > $work/bin/fake
  chmod +x $work/bin/fake
  rehash
}
runs() { [[ -f $work/count ]] && print $(( $(wc -l < $work/count) )) || print 0 }

make_fake v1
VALUE=; __cached_eval fake fake --zsh
check "初回はコマンドを実行して読み込む" "$VALUE/$(runs)" "v1/1"

VALUE=; __cached_eval fake fake --zsh
check "2 回目はキャッシュを読み、コマンドを実行しない" "$VALUE/$(runs)" "v1/1"

sleep 1; make_fake v2
VALUE=; __cached_eval fake fake --zsh
check "コマンドが更新されたら作り直す" "$VALUE/$(runs)" "v2/2"

VALUE=; __cached_eval fake fake --other
check "引数が変わったら作り直す" "$VALUE/$(runs)" "v2/3"

# 同じ実体を別のパスから呼ぶようになったら作り直す
# (出力に呼び出し元のパスが埋め込まれることがあるため。例: mise activate)
mkdir -p $work/other
ln -s $work/bin/fake $work/other/fake
path=($work/other ${path:#$work/bin})
rehash
VALUE=; __cached_eval fake fake --other
check "呼び出し元のパスが変わったら作り直す" "$VALUE/$(runs)" "v2/4"
path=($work/bin ${path:#$work/other})
rehash

__cached_eval missing missing-command-xyz
check "コマンドが無ければ 1 を返す" "$?" "1"

print
(( failures > 0 )) && { print "$failures failed"; exit 1 }
print "all passed"
