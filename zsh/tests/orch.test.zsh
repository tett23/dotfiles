#!/usr/bin/env zsh
# bin/orch の role の名前の確かめのテスト (docs/adr/0131)。使い方: zsh zsh/tests/orch.test.zsh
# tmux は PATH の先頭の偽のコマンドで置き換え、本物のウィンドウに触れない
emulate -L zsh
setopt no_unset no_bg_nice

local root=${0:A:h:h:h}
local orch=$root/bin/orch
local work=$(mktemp -d "${TMPDIR:-/tmp}/orch-test.XXXXXX")
trap "command rm -rf -- ${(q)work}" EXIT

mkdir -p $work/bin
cat > $work/bin/tmux <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> $work/tmux.log
EOF
cat > $work/bin/claude <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x $work/bin/tmux $work/bin/claude
export PATH=$work/bin:$PATH

local -i failures=0
check() {
  if [[ $2 == $3 ]]; then print -r -- "PASS $1"; else print -r -- "FAIL $1 expected=${(q+)3} actual=${(q+)2}"; (( failures++ )); fi
}

# 使い捨てのリポジトリを $work/outer/repo に作り、その外の $work/outer/outside に印を置く
fresh() {
  command rm -rf -- $work/outer $work/tmux.log
  mkdir -p $work/outer/repo $work/outer/outside
  print keep > $work/outer/outside/mark
  git -C $work/outer/repo init -q
  (cd $work/outer/repo && $orch init >/dev/null)
}

# repo の中で orch を動かし、"終了コード|標準エラー" を返す
run_orch() {
  local err code
  (cd $work/outer/repo && $orch "$@" </dev/null >/dev/null 2>$work/err); code=$?
  err=$(<$work/err)
  print -r -- "$code|$err"
}

# .orch の下のファイルとディレクトリの一覧
tree_of() { (cd $work/outer/repo && find .orch | sort) }

tmux_calls() { [[ -f $work/tmux.log ]] && wc -l < $work/tmux.log | tr -d ' ' || print 0 }

local r before
fresh
mkdir -p $work/outer/repo/.orch/roles/x
before=$(tree_of)
r=$(run_orch cleanup --role ../../../outside)
check "ADR 0131 I1: cleanup --role ../../../outside は 1 で終わる" "${r%%|*}" "1"
check "ADR 0131 I1: cleanup --role ../../../outside は外のディレクトリを残す" "$(<$work/outer/outside/mark)" "keep"
check "ADR 0131 I1: cleanup --role ../../../outside は .orch を変えない" "$(tree_of)" "$before"
check "ADR 0131 I1: 名前の決まりを標準エラーに出す" "$([[ ${r#*|} == *'role は [a-zA-Z0-9_-] のみ'* ]] && print yes)" "yes"

for bad in .. a/b '' 'a b' 'é' '*'; do
  fresh
  before=$(tree_of)
  r=$(run_orch cleanup --role "$bad")
  check "ADR 0131 I1: cleanup --role ${(q+)bad} は 1 で終わり、何も変えない" "${r%%|*}|$(tree_of)|$(<$work/outer/outside/mark)" "1|$before|keep"
  check "ADR 0131 I1: cleanup --role ${(q+)bad} は名前の決まりで止まる" "$([[ ${r#*|} == *'role は [a-zA-Z0-9_-] のみ'* ]] && print yes)" "yes"
done

for sub in wait collect; do
  fresh
  before=$(tree_of)
  r=$(run_orch $sub --role ../x)
  check "ADR 0131 I1: $sub --role ../x は 1 で終わる" "${r%%|*}" "1"
  check "ADR 0131 I1: $sub --role ../x は名前の決まりで止まる" "$([[ ${r#*|} == *'role は [a-zA-Z0-9_-] のみ'* ]] && print yes)" "yes"
  check "ADR 0131 I1: $sub --role ../x は .orch を変えない" "$(tree_of)" "$before"
done

fresh
before=$(tree_of)
r=$(run_orch spawn --role ../x --model claude)
check "ADR 0131 I1: spawn --role ../x は 1 で終わる" "${r%%|*}" "1"
check "ADR 0131 I1: spawn --role ../x は .orch/roles の下に何も作らない" "$(tree_of)" "$before"
check "ADR 0131 I1: spawn --role ../x は tmux を呼ばない" "$(tmux_calls)" "0"

# 値の無い --role は、止まらずに 1 で終わる (3 秒で区切る)
for sub in cleanup wait collect spawn; do
  fresh
  (cd $work/outer/repo && $orch $sub --role </dev/null >/dev/null 2>&1) &
  local pid=$! code=timeout
  local -i i
  for i in {1..30}; do
    if ! kill -0 $pid 2>/dev/null; then wait $pid; code=$?; break; fi
    sleep 0.1
  done
  if [[ $code == timeout ]]; then kill $pid 2>/dev/null; wait $pid 2>/dev/null; fi
  check "ADR 0131 I3: $sub --role (値なし) は 1 で終わる" "$code" "1"
done

for good in impl-1_A a; do
  fresh
  mkdir -p $work/outer/repo/.orch/roles/$good
  r=$(run_orch cleanup --role $good)
  check "ADR 0131 I2: cleanup --role $good は片付けて 0 で終わる" "${r%%|*}|$([[ -d $work/outer/repo/.orch/roles/$good ]] && print left || print gone)" "0|gone"
  check "ADR 0131 I2: cleanup --role $good は名前の決まりで拒まない" "$([[ ${r#*|} == *'role は'* ]] && print rejected || print ok)" "ok"
done

for sub in wait collect; do
  fresh
  r=$(run_orch $sub --role ok-name_1 --timeout 0)
  [[ $sub == collect ]] && r=$(run_orch $sub --role ok-name_1)
  check "ADR 0131 I2: $sub --role ok-name_1 は名前の決まりで拒まない" "$([[ ${r#*|} == *'role は'* ]] && print rejected || print ok)" "ok"
done

(( failures == 0 )) || { print "$failures failed"; exit 1 }
print "all passed"
