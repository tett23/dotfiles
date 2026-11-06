#!/usr/bin/env zsh
# bin/prh-claude-hook のテスト (docs/adr/0078)。使い方: zsh zsh/tests/prh-claude-hook.test.zsh
# prh・jq・gawk の無い環境 (CI など) では飛ばす
emulate -L zsh
setopt no_unset

local root=${0:A:h:h:h}
local hook=$root/bin/prh-claude-hook
local prh_bin=${commands[prh]:-$HOME/.local/share/mise/shims/prh}
if [[ ! -x $prh_bin ]] || (( ! $+commands[jq] || ! $+commands[gawk] )); then
  print "SKIP prh・jq・gawk のどれかがありません"
  exit 0
fi

local work=$(mktemp -d "${TMPDIR:-/tmp}/prh-claude-hook-test.XXXXXX")
trap "command rm -r -- ${(q)work}" EXIT
cat > $work/rules.yml <<'EOF'
version: 1
rules:
  - expected: ウィンドウ
    pattern: /窓(?!口)/
EOF
export PRH_CLAUDE_RULES=$work/rules.yml

local -i failures=0
check() {
  if [[ $2 == $3 ]]; then print -r -- "PASS $1"; else print -r -- "FAIL $1 expected=${(q+)3} actual=${(q+)2}"; (( failures++ )); fi
}

# hook を JSON (file_path) で動かし、"終了コード|標準出力|標準エラー" を返す
run_hook() {
  local json=$1 out err code
  out=$(print -r -- "$json" | $hook 2>$work/err); code=$?
  err=$(<$work/err)
  print -r -- "$code|$out|$err"
}
json_for() { print -r -- "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$1\"}}" }

print -r -- '窓を開く。' > $work/hit.md
local r=$(run_hook "$(json_for $work/hit.md)")
check "当たると終了コード 2" "${r%%|*}" "2"
check "当たると標準エラーに直す表記を出す" "$([[ $r == *"窓 → ウィンドウ"* ]] && print yes)" "yes"
check "標準エラーに元のファイルの名前と行・列を出す" "$([[ $r == *"$work/hit.md(1,1): 窓 → ウィンドウ"* ]] && print yes)" "yes"
check "標準エラーに辞書の場所を出す" "$([[ $r == *"$work/rules.yml"* ]] && print yes)" "yes"

print -r -- '窓口へ行く。' > $work/madoguchi.md
check "窓口だけなら何も出さない" "$(run_hook "$(json_for $work/madoguchi.md)")" "0||"
print -r -- 'ウィンドウを開く。' > $work/clean.md
check "当たる表記が無ければ何も出さない" "$(run_hook "$(json_for $work/clean.md)")" "0||"

print -r -- '窓を開く。' > $work/hit.txt
check ".md でなければ何も出さない" "$(run_hook "$(json_for $work/hit.txt)")" "0||"
check "無いファイルなら何も出さない" "$(run_hook "$(json_for $work/missing.md)")" "0||"
check "file_path が無ければ何も出さない" "$(run_hook '{"tool_name":"Write","tool_input":{}}')" "0||"

cat > $work/code.md <<'EOF'
```
窓
```
~~~sh
echo 窓
~~~
文中の `窓` はコード。
EOF
check "コードブロックとインラインのコードの中だけなら何も出さない" "$(run_hook "$(json_for $work/code.md)")" "0||"

cat > $work/mixed.md <<'EOF'
```
窓
```
`窓` と 窓 を書く。
EOF
r=$(run_hook "$(json_for $work/mixed.md)")
check "本文の箇所だけを、元の行・列で出す" \
  "$(print -r -- "${r#*|*|}" | grep -c 'mixed.md(')|$([[ $r == *"$work/mixed.md(4,7): 窓 → ウィンドウ"* ]] && print yes)" "1|yes"

# 実際の辞書
"$prh_bin" --rules $root/prh/prh.yml --rules-json >/dev/null 2>&1
check "実際の辞書を prh が読める" "$?" "0"
local hit=$(PRH_CLAUDE_RULES=$root/prh/prh.yml run_hook "$(json_for $work/hit.md)")
local miss=$(PRH_CLAUDE_RULES=$root/prh/prh.yml run_hook "$(json_for $work/madoguchi.md)")
check "実際の辞書で窓が当たり、窓口は当たらない" "${hit%%|*} ${miss%%|*}" "2 0"

# PATH にも mise の shims にも prh が無いとき
mkdir -p $work/bin $work/home
for c in jq gawk mktemp rm cat sed; do ln -s ${commands[$c]} $work/bin/$c; done
check "prh が無ければ何も出さない" \
  "$(print -r -- "$(json_for $work/hit.md)" | PATH=$work/bin HOME=$work/home /bin/sh $hook 2>&1; print -n "|$?")" "|0"

print
(( failures > 0 )) && { print "$failures failed"; exit 1 }
print "all passed"
