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

# Codex の apply_patch (tool_input.command にパッチの全文、パスは cwd からの相対か絶対)
codex_json() { jq -cn --arg c "$1" --arg d "$2" --arg t "${3:-apply_patch}" '{tool_name:$t,tool_input:{command:$c},cwd:$d}' }
local patch_hit=$'*** Begin Patch\n*** Update File: hit.md\n@@\n-x\n+窓を開く。\n*** End Patch'
r=$(run_hook "$(codex_json $patch_hit $work)")
check "ADR 0130 I1: Codex: 相対のパスの .md に当たると終了コード 2" "${r%%|*}" "2"
check "ADR 0130 I1: Codex: 標準エラーに cwd を付けたファイルの名前を出す" "$([[ $r == *"$work/hit.md(1,1): 窓 → ウィンドウ"* ]] && print yes)" "yes"
r=$(run_hook "$(codex_json $'*** Begin Patch\n*** Add File: '$work$'/hit.md\n+窓\n*** End Patch' /)")
check "ADR 0130 I1: Codex: 絶対のパスの追加でも当たる" "${r%%|*}" "2"
r=$(run_hook "$(codex_json $'*** Begin Patch\n*** Update File: clean.md\n*** Update File: hit.md\n*** End Patch' $work)")
check "ADR 0130 I1, I2: Codex: 複数のファイルのうち当たるものだけを出す" "$(print -r -- "$r" | grep -c 'hit.md(')|$(print -r -- "$r" | grep -c 'clean.md(')" "1|0"
r=$(run_hook "$(codex_json $'*** Begin Patch\n*** Update File: old.md\n*** Move to: hit.md\n*** End Patch' $work)")
check "ADR 0130 I1: Codex: 移した先のファイルを検査する" "${r%%|*}" "2"
check "ADR 0130 I2: Codex: 消したファイルと .md でないファイルは何も出さない" \
  "$(run_hook "$(codex_json $'*** Begin Patch\n*** Delete File: hit.md\n*** Update File: hit.txt\n*** End Patch' $work)")" "0||"
check "ADR 0130 I2: Codex: 当たる表記が無ければ何も出さない" "$(run_hook "$(codex_json $'*** Begin Patch\n*** Update File: clean.md\n*** End Patch' $work)")" "0||"
check "ADR 0130 I2: Codex: パッチの無い Bash は何も出さない" "$(run_hook "$(codex_json 'ls' $work Bash)")" "0||"
r=$(run_hook "$(codex_json $'apply_patch <<\'EOF\'\n*** Begin Patch\n*** Update File: hit.md\n*** End Patch\nEOF' $work Bash)")
check "ADR 0130 I1: Codex: Bash のヒアドキュメントの中のパッチも検査する" "${r%%|*}" "2"

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
