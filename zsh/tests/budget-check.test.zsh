#!/usr/bin/env zsh
# bin/budget-check のテスト (docs/adr/0128)。使い方: zsh zsh/tests/budget-check.test.zsh
# gh は PATH の先頭に置いた偽の gh で置き換え、issue とコメントとラベルの状態をファイルに記録する。
# jq と git の無い環境では飛ばす
emulate -L zsh
setopt no_unset

local root=${0:A:h:h:h}
local bc=$root/bin/budget-check
if (( ! $+commands[jq] || ! $+commands[git] )); then
  print "SKIP jq か git がありません"
  exit 0
fi

local work=$(mktemp -d "${TMPDIR:-/tmp}/budget-check-test.XXXXXX")
trap "command rm -rf -- ${(q)work}" EXIT

# 偽の gh。状態は $FAKE_GH_STATE の下に置く:
#   issues.json   [{number,title,body,labels:[名前],state}]
#   comments/<番号>.json  [{body}]
#   calls.log     呼ばれた引数を一行ずつ
#   FAKE_GH_FAIL  この部分文字列を引数に含む呼び出しを失敗させる
mkdir -p $work/bin
cat > $work/bin/gh <<'EOF'
#!/usr/bin/env zsh
emulate -L zsh
st=$FAKE_GH_STATE
print -r -- "$*" >> $st/calls.log
if [[ -n ${FAKE_GH_FAIL:-} && "$*" == *${FAKE_GH_FAIL}* ]]; then print -u2 "fake gh: fail"; exit 1; fi
case "$1 $2" in
  ("label create") print -r -- "$3" >> $st/labels; exit 0 ;;
  ("issue list")
    local label= state= limit=30
    shift 2
    while (( $# )); do
      case $1 in
        (--label) label=$2; shift 2 ;;
        (--state) state=$2; shift 2 ;;
        (--limit) limit=$2; shift 2 ;;
        (*) shift ;;
      esac
    done
    jq -c --arg l "$label" --arg s "$state" --argjson n "$limit" \
      '[.[] | select(.state == $s and (.labels | index($l)))] | sort_by(-.number) | .[:$n] | map({number,title,body})' $st/issues.json
    exit 0 ;;
  ("issue create")
    local title= body= label=
    shift 2
    while (( $# )); do
      case $1 in
        (--title) title=$2; shift 2 ;;
        (--body) body=$2; shift 2 ;;
        (--label) label=$2; shift 2 ;;
        (*) shift ;;
      esac
    done
    local n=$(( $(jq 'map(.number) | max // 0' $st/issues.json) + 1 ))
    jq -c --argjson n $n --arg t "$title" --arg b "$body" --arg l "$label" \
      '. + [{number:$n, title:$t, body:$b, labels:[$l], state:"open"}]' $st/issues.json > $st/tmp && mv $st/tmp $st/issues.json
    print "https://example.invalid/issues/$n"; exit 0 ;;
  ("issue comment")
    local n=$3 body=
    shift 3
    while (( $# )); do
      case $1 in (--body) body=$2; shift 2 ;; (*) shift ;; esac
    done
    [[ -f $st/comments/$n.json ]] || print '[]' > $st/comments/$n.json
    jq -c --arg b "$body" '. + [{body:$b}]' $st/comments/$n.json > $st/tmp && mv $st/tmp $st/comments/$n.json
    exit 0 ;;
esac
if [[ $1 == api ]]; then
  local apipath=${@[-1]} n
  n=${${apipath%/comments}##*/}
  local f=$st/comments/$n.json
  [[ -f $f ]] || { print '[[]]'; exit 0; }
  # ページを 30 件ずつに分け、--slurp のときは配列の配列で返す
  if [[ "$*" == *--slurp* ]]; then
    jq -c '[range(0; (length / 30 | ceil) | if . == 0 then 1 else . end) as $i | .[$i*30:($i+1)*30]]' $f
  else
    jq -c '.[:30]' $f
  fi
  exit 0
fi
print -u2 "fake gh: unknown: $*"; exit 2
EOF
chmod +x $work/bin/gh

local -i failures=0
check() {
  if [[ $2 == $3 ]]; then print -r -- "PASS $1"; else print -r -- "FAIL $1 expected=${(q+)3} actual=${(q+)2}"; (( failures++ )); fi
}

local repo st
# 新しいリポジトリと状態を作る。引数は予算の一覧の行 (無ければファイルを作らない。"-" なら表だけ)
setup() {
  repo=$(mktemp -d $work/repo.XXXXXX)
  st=$repo.state
  mkdir -p $st/comments
  print '[]' > $st/issues.json
  : > $st/calls.log
  git -C $repo init -q
  if (( $# )); then
    mkdir -p $repo/docs
    {
      print '# 予算'
      print
      print '| 名前 | 指標と単位 | 比較 | 値 | 計測のコマンド | ADR |'
      print '| --- | --- | --- | --- | --- | --- |'
      [[ $1 == - ]] || print -rl -- "$@"
    } > $repo/docs/budgets.md
  fi
}
# budget-check を動かし、終了コードを $code、標準出力を $out、標準エラーを $err に入れる
local code out err
run_bc() {
  out=$(cd $repo && PATH=$work/bin:$PATH FAKE_GH_STATE=$st FAKE_GH_FAIL=${FAKE_GH_FAIL:-} GITHUB_SHA=abc1234 GITHUB_SERVER_URL=https://example.invalid \
    GITHUB_REPOSITORY=o/r GITHUB_RUN_ID=1 sh $bc "$@" 2>$st/err); code=$?
  err=$(<$st/err)
}
issues() { jq -r --arg t "$1" '[.[] | select(.title == $t)] | length' $st/issues.json }
comments() { [[ -f $st/comments/$1.json ]] && jq length $st/comments/$1.json || print 0 }
calls() { grep -c -- "$1" $st/calls.log }
row() { print -r -- "| $1 | ms | $2 | $3 | \`printf $4\` | ADR 0001 A1 |" }
title() { print -r -- "予算違反: $1 (docs/budgets.md)" }
# 開いた issue を一つ置く。引数は番号、題、本文
put_issue() {
  jq -c --argjson n $1 --arg t "$2" --arg b "$3" '. + [{number:$n, title:$t, body:$b, labels:["budget-violation"], state:"open"}]' \
    $st/issues.json > $st/tmp && mv $st/tmp $st/issues.json
}
mark() { print -r -- "<!-- budget-check: value=$1 state=$2 -->" }

# I9: 予算が無いとき
setup; run_bc
check "ADR 0128 I9: docs/budgets.md が無ければ「予算なし」で終了コード 0" "$code|$([[ $out == *予算なし* ]] && print y)" "0|y"
check "ADR 0128 I9: docs/budgets.md が無ければ gh を呼ばない" "$(wc -l < $st/calls.log | tr -d ' ')" "0"
setup -; run_bc
check "ADR 0128 I9: 表に行が無ければ終了コード 0 で gh を呼ばない" "$code|$(wc -l < $st/calls.log | tr -d ' ')" "0|0"

# I8: 一覧が読めないとき
setup; run_bc docs/missing.md
check "ADR 0128 I8: 引数で渡したファイルが無ければ終了コード 1" "$code" "1"
setup; mkdir -p $repo/docs; print '# 表なし' > $repo/docs/budgets.md; run_bc
check "ADR 0128 I8: 決まった見出しの表が無ければ終了コード 1" "$code" "1"
local outside=$(mktemp -d $work/outside.XXXXXX)
out=$(cd $outside && PATH=$work/bin:$PATH FAKE_GH_STATE=$work sh $bc 2>/dev/null); code=$?
check "ADR 0128 I8: git のリポジトリの外で動かすと終了コード 1" "$code" "1"

# I5: 等しい値は満たす
setup "$(row lat '<=' 100 100)"; run_bc
check "ADR 0128 I5, I4: <= 100 に対して 100 は満たし、issue を作らない" "$code|$(issues "$(title lat)")" "0|0"
setup "$(row fps '>=' 30 30)"; run_bc
check "ADR 0128 I5: >= 30 に対して 30 は満たす" "$code|$(issues "$(title fps)")" "0|0"

# I1, I2: 違反で issue を一つ作る
setup "$(row lat '<=' 100 100.0001)"; run_bc
check "ADR 0128 I1: <= 100 に対して 100.0001 は違反で issue を一つ作る" "$code|$(issues "$(title lat)")" "0|1"
check "ADR 0128 I1: issue を作る前にラベルを用意する" "$(calls 'label create budget-violation')" "1"
check "ADR 0128 I1: 本文の末尾に違反の印を置く" "$(jq -r '.[0].body' $st/issues.json | grep -c 'budget-check: value=100.0001 state=violation')" "1"
check "ADR 0128 I1: 本文にコミットと実行の URL を書く" \
  "$(jq -r '.[0].body' $st/issues.json | grep -c -e abc1234 -e 'https://example.invalid/o/r/actions/runs/1')" "2"
check "ADR 0128 I2: issue を探すとき --limit 1000 を渡す" "$(calls 'issue list .*--limit 1000')" "1"

# I2, I3: 2 回目
run_bc
check "ADR 0128 I2, I3: 違反のまま同じ値なら issue もコメントも増えない" "$(issues "$(title lat)")|$(comments 1)" "1|0"
setup "$(row lat '<=' 100 120)"; put_issue 1 "$(title lat)" "$(mark 110 violation)"; run_bc
check "ADR 0128 I3: 違反のまま前より悪ければコメントが一つ増える" "$(issues "$(title lat)")|$(comments 1)" "1|1"
check "ADR 0128 I3: 違反のコメントに前の値との差を書く" "$(jq -r '.[0].body' $st/comments/1.json | grep -c '110')" "1"
setup "$(row lat '<=' 100 105)"; put_issue 1 "$(title lat)" "$(mark 110 violation)"; run_bc
check "ADR 0128 I3: 違反のまま前よりよければコメントは増えない" "$(comments 1)" "0"
setup "$(row fps '>=' 30 20)"; put_issue 1 "$(title fps)" "$(mark 25 violation)"; run_bc
check "ADR 0128 I3: >= の予算では値が小さくなると悪い" "$(comments 1)" "1"

# I4: 満たしたとき
setup "$(row lat '<=' 100 90)"; put_issue 1 "$(title lat)" "$(mark 110 violation)"; run_bc
check "ADR 0128 I4: 違反の issue があり満たしたら「予算を満たした」が一つ増える" "$(comments 1)|$(jq -r '.[0].body' $st/comments/1.json | grep -c 'state=ok')" "1|1"
check "ADR 0128 I4: issue は開いたまま" "$(jq -r '.[0].state' $st/issues.json)" "open"
run_bc
check "ADR 0128 I4: 満たした後の 2 回目も満たせばコメントは増えない" "$(comments 1)" "1"
setup "$(row lat '<=' 100 120)"; put_issue 1 "$(title lat)" "$(mark 110 violation)"
print -r -- "[{\"body\":\"ok $(mark 90 ok)\"}]" > $st/comments/1.json; run_bc
check "ADR 0128 I3: 満たした後にまた違反したらコメントが一つ増える" "$(comments 1)" "2"

# I1, I2: 同じ題の issue
setup "$(row lat '<=' 100 120)"; put_issue 3 "$(title lat)" "$(mark 110 violation)"; put_issue 7 "$(title lat)" "$(mark 110 violation)"; run_bc
check "ADR 0128 I1, I2: 同じ題とラベルが二つあれば番号の小さいほうにだけコメントし issue を作らない" \
  "$(comments 3)|$(comments 7)|$(issues "$(title lat)")" "1|0|2"
setup "$(row lat '<=' 100 120)"
jq -c --arg t "$(title lat)" '. + [{number:1, title:$t, body:"", labels:["budget-violation"], state:"closed"}]' $st/issues.json > $st/tmp && mv $st/tmp $st/issues.json
run_bc
check "ADR 0128 I1: 同じ題で閉じた issue だけなら issue を一つ作る" "$(jq --arg t "$(title lat)" '[.[] | select(.title == $t and .state == "open")] | length' $st/issues.json)" "1"
setup "$(row lat '<=' 100 120)"
jq -c --arg t "$(title lat)" '. + [{number:1, title:$t, body:"", labels:[], state:"open"}]' $st/issues.json > $st/tmp && mv $st/tmp $st/issues.json
run_bc
check "ADR 0128 I1: ラベルの無い同じ題の issue は使わずラベル付きを一つ作る" "$(jq --arg t "$(title lat)" '[.[] | select(.title == $t and (.labels | index("budget-violation")))] | length' $st/issues.json)|$(comments 1)" "1|0"

# I10: 前の記録の読み方
setup "$(row lat '<=' 100 120)"; put_issue 1 "$(title lat)" "印なし"; run_bc
check "ADR 0128 I3, I10: 印が無ければ前の記録が無いものとして違反のコメントを一つ足す" "$(comments 1)" "1"
setup "$(row lat '<=' 100 120)"; put_issue 1 "$(title lat)" "$(mark 130 violation)"
print -r -- "[{\"body\":\"<!-- budget-check: value=abc state=violation -->\"}]" > $st/comments/1.json; run_bc
check "ADR 0128 I10: いちばん新しい印が壊れていれば古い正しい印を読む (130 より 120 はよいのでコメントしない)" "$(comments 1)" "1"
setup "$(row lat '<=' 100 120)"; put_issue 1 "$(title lat)" "$(mark 100.5 violation)"
jq -nc --arg m "$(mark 119 violation)" '[range(0;40) | {body:"x"}] + [{body:$m}]' > $st/comments/1.json; run_bc
check "ADR 0128 I10: コメントが 31 件以上あっても最後のページの印を読む (119 より 120 は悪い)" "$(comments 1)" "42"
check "ADR 0128 I10: コメントは --paginate --slurp で読む" "$(calls 'api --paginate --slurp')" "1"

# I6, I8: エラーの予算
setup "$(row a '<=' 100 120)" "| b | ms | <= | 100 | \`false\` | ADR 0001 A1 |"; run_bc
check "ADR 0128 I6, I8: 計測が失敗した予算は何もせず、ほかの違反は issue を作り、終了コード 1" \
  "$code|$(issues "$(title a)")|$(issues "$(title b)")" "1|1|0"
for v in abc '""' "'\\n'"; do
  setup "| v | ms | <= | 100 | \`printf $v\` | ADR 0001 A1 |"; run_bc
  check "ADR 0128 I6: 計測の値が $v ならエラー" "$code|$(issues "$(title v)")" "1|0"
done
setup "$(row c '<' 100 120)"; run_bc
check "ADR 0128 I6: 比較が < ならエラー" "$code|$(issues "$(title c)")" "1|0"
setup "$(row d '<=' 1e3 120)"; run_bc
check "ADR 0128 I6: 値が 1e3 ならエラー" "$code|$(issues "$(title d)")" "1|0"
setup "| e | ms | <= | 100 | \`printf 120\` |"; run_bc
check "ADR 0128 I6: セルが 5 つの行はエラー" "$code|$(issues "$(title e)")" "1|0"
setup "$(row f '<=' 100 120)" "$(row g '<=' 100 90)" "$(row f '<=' 100 130)"; run_bc
check "ADR 0128 I6: 名前が前のどれかの行と同じ行はエラーで、一つ目は確かめる" "$code|$(issues "$(title f)")|$(jq -r '.[0].body' $st/issues.json | grep -c 'value=120 ')" "1|1|1"
setup "$(row h '<=' 100 120)"; FAKE_GH_FAIL='issue create' run_bc
check "ADR 0128 I6, I8: gh issue create が失敗したらその予算はエラーで終了コード 1" "$code|$(issues "$(title h)")" "1|0"

# 二つの予算
setup "$(row i '<=' 100 120)" "$(row j '<=' 100 90)"; run_bc
check "ADR 0128 I1, I4: 違反の予算だけに issue を作る" "$(issues "$(title i)")|$(issues "$(title j)")" "1|0"

# I11: セルの読み方
setup "| k | 行 | <= | 2 | \`seq 1 3 \\| wc -l\` | ADR 0001 A1 |"; run_bc
check "ADR 0128 I11: \\| を | に戻して動かす (3 行は <= 2 の違反)" "$code|$(issues "$(title k)")" "0|1"

# I12: 題
setup "$(row l '<=' 100 120)"; run_bc ./docs/budgets.md
check "ADR 0128 I12: ./docs/budgets.md を渡しても題のパスは docs/budgets.md" "$(issues "$(title l)")" "1"

# I7: dry-run
setup "$(row m '<=' 100 120)"; run_bc --dry-run
check "ADR 0128 I7: --dry-run では書き込みの gh を呼ばない" "$(calls 'label create')|$(calls 'issue create')|$(calls 'issue comment')" "0|0|0"

# I8: --fail-on-violation
setup "$(row n '<=' 100 120)"; run_bc --fail-on-violation
check "ADR 0128 I8: 違反があり --fail-on-violation でエラーが無ければ終了コード 2" "$code" "2"
setup "$(row n '<=' 100 90)"; run_bc --fail-on-violation
check "ADR 0128 I8: 違反が無ければ --fail-on-violation でも終了コード 0" "$code" "0"

# I2: 件数
setup "$(row o '<=' 100 120)"
jq -nc --arg t "$(title o)" '[range(1;1001) | {number:., title:("other " + tostring), body:"", labels:["budget-violation"], state:"open"}] | .[0].title = $t' > $st/issues.json
run_bc
check "ADR 0128 I2: ラベル付きの開いた issue がちょうど 1000 件でも、いちばん古い同じ題の issue が見つかる" "$(issues "$(title o)")|$(comments 1)" "1|1"

print
(( failures > 0 )) && { print "$failures failed"; exit 1 }
print "all passed"
