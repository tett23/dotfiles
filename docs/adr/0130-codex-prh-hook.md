# ADR 0130: Codex の hook で prh を動かす

Status: accepted

## 文脈

[ADR 0115](0115-codex-adr-guard-hook.md) は、Codex の hook (`codex/hooks.json`) で adr-guard を動かすと決め、その「実装しないこと」に「Codex の hook で、ほかの検査 (prh など) を動かすこと」を置いた。
ところが、コミット `91e3814` (2026-11-16) は、ADR を作らずに、`codex/hooks.json` の `PostToolUse` で `bin/prh-claude-hook` を動かす変更を入れた。
このとき、本人は「Claude と Codex で設定に差分ができてるので同期。これは ADR 不要」と頼み、同期の作業として進めた。
しかし、この変更は [ADR 0115](0115-codex-adr-guard-hook.md) の決定とぶつかる。
2026-11-16 の ADR 違反の監査 ([docs/audits/2026-11-16-conformance-audit.md](../audits/2026-11-16-conformance-audit.md)) は、これを重大度「高」の違反として挙げた。

そのため、この ADR で、Codex の hook で prh を動かすことを決め直し、[ADR 0115](0115-codex-adr-guard-hook.md) の「実装しないこと」のその項目を置き換える。
実装は `91e3814` で終わっているので、この ADR はその実装を追認する。

## 調査した事項

- `codex/hooks.json` には、`PreToolUse` の `adr-guard codex-hook --allow-status` と、`PostToolUse` の `${DOTFILES:-$HOME/dotfiles}/bin/prh-claude-hook` がある。どちらも `matcher` は `^(apply_patch|Bash)$` である (`cat codex/hooks.json`)。
- `bin/prh-claude-hook` は、hook の入力の `tool_input.file_path` があればそのファイルを、無ければ `tool_input.command` の中のパッチの `*** Add File:`、`*** Update File:`、`*** Move to:` の行のパスを、入力の `cwd` からの相対か絶対として読み、そのうちの Markdown を prh の辞書で検査する (`bin/prh-claude-hook` の 27〜41 行)。
- `91e3814` は、`zsh/tests/prh-claude-hook.test.zsh` に Codex の入力のテストを 9 つ足した。相対と絶対のパス、複数のファイル、`Move to`、消したファイルと Markdown でないファイル、パッチの無い `Bash`、`Bash` のヒアドキュメントの中のパッチを確かめる (`git show 91e3814 -- zsh/tests/prh-claude-hook.test.zsh`)。
- `docs/specifications.md` の prh の項には、Codex でも同じ hook を動かすことが書いてある (`91e3814` で足した 2 行)。
- Codex が `PostToolUse` の hook の終了コード 2 をどう扱うか (モデルに知らせるか) は、確かめていない。[ADR 0115](0115-codex-adr-guard-hook.md) が確かめたのは `PreToolUse` だけである。
- Claude Code の側の prh の hook は、[ADR 0078](0078-prh-dictionary-and-claude-hook.md) で決めた。直す表記があれば終了コード 2 で終わり、書き込みは取り消さない。

## 実装すること

`91e3814` の実装をそのまま認め、次のことを決める。

- Codex の `PostToolUse` の hook で、`bin/prh-claude-hook` を動かす。`matcher` は `^(apply_patch|Bash)$` とする。
- `bin/prh-claude-hook` は、Codex の `apply_patch` のパッチ (`Bash` の中のパッチを含む) から、足したファイル、変えたファイル、移した先のファイルのパスを読み、そのうちの Markdown を検査する。
- [ADR 0115](0115-codex-adr-guard-hook.md) のステータスを、`superseded [{"part":"実装しないこと (Codex の hook で、ほかの検査 (prh など) を動かすこと)","by":["docs/adr/0130-codex-prh-hook.md"]}]` にする。「実装しないこと」のほかの 2 項目は変えない。

新しく変えるコードは無い。

## 実装しないこと

- prh 以外の検査を、Codex の hook で動かすこと。足すときは、別の ADR で決める。
- `91e3814` のコミットを書き換えること。

## 不変条件

- I1: Codex の入力 (`tool_input.command` と `cwd`) で、パッチが足したか、変えたか、移した先の Markdown に辞書の表記があるとき、`bin/prh-claude-hook` は終了コード 2 で終わり、そのファイルの名前と位置を標準エラーに出す。
- I2: Codex の入力で、パッチが触れるファイルが、消したファイル、Markdown でないファイル、辞書の表記の無い Markdown だけのとき、またはパッチの無い `Bash` のコマンドのとき、`bin/prh-claude-hook` は何も出さず、終了コード 0 で終わる。

境界の入力:

| 入力 | 期待 | 不変条件 |
| --- | --- | --- |
| パッチの無い `Bash` (`ls`) | 何も出さず 0 | I2 |
| 相対のパスの `.md` 一つに辞書の表記 | 2 で、`cwd` を付けたファイルの名前を出す | I1 |
| 絶対のパスの追加 | 2 | I1 |
| 二つのファイルのうち一つだけに表記 | 表記のあるファイルだけを出す | I1, I2 |
| `Move to` の先に表記 | 2 | I1 |
| `Delete File` と `.txt` | 何も出さず 0 | I2 |
| 表記の無い `.md` 一つ | 何も出さず 0 | I2 |
| `Bash` のヒアドキュメントの中のパッチ | 2 | I1 |

## 受けいれ条件

- A1: `zsh/tests/prh-claude-hook.test.zsh` の Codex のテストが通る。
- A2: [ADR 0115](0115-codex-adr-guard-hook.md) のステータスが、上の `superseded` になっている。
- A3: Codex に辞書の表記 (`窓` など) を含む Markdown を書かせると、hook の出力がモデルに渡り、モデルが表記を直そうとする。

## テスト設計

- A1: `91e3814` で足したテストの名前を、[ADR 0124](0124-invariant-and-test-naming.md) の形 (`ADR 0130 I1: …`、`ADR 0130 I2: …`) に付け直し、`zsh zsh/tests/prh-claude-hook.test.zsh` を動かす。
- A2: `rg -n '^Status:' docs/adr/0115-codex-adr-guard-hook.md` で確かめる。
- A3: 手で確かめる。Codex の利用の上限が戻る 2026-11-20 9:40 より後に行う。モデルに渡らないときは、Codex での hook の扱いを調べ、別の ADR で決め直す。

## トレードオフ

- `matcher` に `Bash` を含めるので、Codex のシェルのコマンドのたびに `bin/prh-claude-hook` が起動する。パッチの無いコマンドでは、JSON を読むだけで終わる。
- `sed -i` などパッチ以外のコマンドで書いた Markdown は、検査しない。
- 実装の後に ADR を書いたので、`91e3814` から、この ADR を採択するまでの間、実装が [ADR 0115](0115-codex-adr-guard-hook.md) とぶつかっていた。

## 参考文献

- dotfiles の [ADR 0078](0078-prh-dictionary-and-claude-hook.md)、[ADR 0115](0115-codex-adr-guard-hook.md)、[ADR 0124](0124-invariant-and-test-naming.md)
- [docs/audits/2026-11-16-conformance-audit.md](../audits/2026-11-16-conformance-audit.md)
- コミット `91e3814`
