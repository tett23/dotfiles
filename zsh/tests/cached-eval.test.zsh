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

# 出力に PATH をその時点の値に固定する行 (mise activate の先頭の 2 行) があっても、読み込む前の PATH を変えない (docs/adr/0051)
print -r -- "#!/bin/sh
cat <<'OUT'
export __MISE_ORIG_PATH='/stale/orig'
export PATH='/stale/shims:/stale/orig'
export SNAPSHOT_OTHER=kept
if [ -z \"\${__MISE_ORIG_PATH:-}\" ]; then
  export __MISE_ORIG_PATH=\"\$PATH\"
fi
OUT" > $work/bin/snapshot
chmod +x $work/bin/snapshot
rehash
local before=$PATH
unset __MISE_ORIG_PATH SNAPSHOT_OTHER
__cached_eval snapshot snapshot activate zsh
check "PATH を固定する行は読み込まない (PATH が変わらない)" "$PATH" "$before"
check "PATH を固定する行以外の export は効く" "${SNAPSHOT_OTHER-}" "kept"
check "字下げした行の PATH (読み込んだ時点の値) は効く" "${__MISE_ORIG_PATH-}" "$before"
PATH=$before; rehash # 失敗したときに後ろのテストが動くよう戻す
check "取り除いた行の数をキャッシュの 2 行目に書く" "$(sed -n 2p $XDG_CACHE_HOME/zsh/snapshot.zsh)" "# removed: 2 lines that pin PATH"

# 空行は残す (複数行の文字列の中の空行が消えると、意味が変わるため)
print -r -- "#!/bin/sh
printf 'export PATH=/stale\\nMULTI=\"a\\n\\nb\"\\n'" > $work/bin/blank
chmod +x $work/bin/blank
rehash
MULTI=; __cached_eval blank blank
check "空行を含む複数行の文字列が変わらない" "$MULTI" $'a\n\nb'
check "取り除くのは PATH を固定する行だけ" "$(sed -n 2p $XDG_CACHE_HOME/zsh/blank.zsh)" "# removed: 1 lines that pin PATH"
PATH=$before; rehash

# 形式の版 (v2) の無い古いキャッシュは作り直す
local real=${${commands[snapshot]}:A} mtime
zstat -A mtime +mtime -- $real
print -r -- "# key: ${commands[snapshot]} $real $mtime snapshot activate zsh"$'\n'"export PATH='/old/cache'" > $XDG_CACHE_HOME/zsh/snapshot.zsh
__cached_eval snapshot snapshot activate zsh
check "形式の版の無い古いキャッシュは作り直し、PATH を変えない" "$PATH" "$before"
PATH=$before; rehash
check "作り直したキャッシュのキーに形式の版がある" "$(head -1 $XDG_CACHE_HOME/zsh/snapshot.zsh)" "# key: v2 ${commands[snapshot]} $real $mtime snapshot activate zsh"

print
(( failures > 0 )) && { print "$failures failed"; exit 1 }
print "all passed"
