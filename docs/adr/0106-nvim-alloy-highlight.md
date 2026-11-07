# ADR 0106: nvim で Alloy を tree-sitter で色付けする

ステータス: 採択

## 文脈

[ADR 0104](0104-nvim-alloy-lsp.md) で、`.als` をファイルタイプ `alloy` にし、Alloy の LSP サーバーを付けた。色付けはしていない。
本人から、Alloy のシンタックスハイライトも入れるよう頼まれた。

調べたことは次のとおり。

- nvim-treesitter (main) の一覧に Alloy の文法は無い。nvim 0.12.6 にも Alloy の syntax は無い。
- GitHub で探した、Alloy (形式仕様の言語。Grafana Alloy とは別) の文法とプラグイン (ghq で取得):

  | リポジトリ | 種類 | 最後のコミット | ライセンス | 中身 |
  | --- | --- | --- | --- | --- |
  | `vincentlu/tree-sitter-alloy` | tree-sitter の文法 | `7bcc865` (2026-03-14) | MIT | Alloy 6 (時相演算子、`var`) を扱う。`src/parser.c` をコミットしている。`queries/highlights.scm` と、7 つのテストのコーパスがある |
  | `vincentlu/alloy.nvim` | nvim のプラグイン | `5a33b5a` (2026-03-07) | MIT | 上の文法を使う。ファイルタイプの判定と、自分の `highlights.scm` |
  | `fore-stun/tree-sitter-alloy` | tree-sitter の文法 | `26d70b6` (2024-03-30) | MIT | テストのコーパスは 1 つ |
  | `bakaq/tree-sitter-alloy6` | tree-sitter の文法 | `b1261e7` (2024-03-24) | 無し | `queries` が無い |
  | `runoshun/vim-alloy` | Vim の syntax | `5bd57c4` (2023-03-05) | 無し | 正規表現の syntax。nvim-lspconfig の `alloy_ls` の説明が挙げている |

- `vincentlu/tree-sitter-alloy`:
  - `tree-sitter.json` の文法の名前は `alloy`、`file-types` は `als`。ファイルタイプ `alloy` と名前が合う。
  - README は、nvim 0.11 以降 (ABI 15) では `main` を使うとする。タグは古い ABI 向けの `abi-13`・`abi-14` だけで、版のタグは無い。
  - `queries/highlights.scm` の capture は、`@keyword`・`@keyword.operator`・`@type.definition`・`@function`・`@label`・`@module`・
    `@variable.member`・`@variable.parameter`・`@operator` など、nvim-treesitter の名前に合う。`indents.scm` などほかの query は無い。
- dotfiles の `nvim/lua/plugins/treesitter.lua` は、nvim-treesitter の一覧に無い文法を `custom_parsers` に書き、`User TSUpdate` で登録している
  ([ADR 0100](0100-nvim-hpeg-golem-emet-highlight-and-emet-lsp.md))。今は `location` (リポジトリの中のサブディレクトリ) を必ず書く作りで、
  `queries` を `location .. "/queries"` にしている。
- nvim-treesitter の `install.lua`: `location` は書かなくてもよく、書かなければリポジトリのルートでビルドする。`revision` を書くと、そのコミットを入れる。

## 実装すること

- `nvim/lua/plugins/treesitter.lua`:
  - `parsers` に `"alloy"` を足す。
  - `custom_parsers` に `alloy = { url = "https://github.com/vincentlu/tree-sitter-alloy", revision = "7bcc865b0d12ff4f20876efd072fd1bc11faff48" }` を足す。
  - `custom_parsers` の登録で、`location` が無いときは `queries` を `"queries"` にし、`revision` があれば `install_info` に渡す。
  - 注釈に、自分のリポジトリでない文法はコミットを固定することと、この ADR を書く。
- `docs/specifications.md` の nvim の tree-sitter の記述に書く。README は nvim の色付けの一覧を持たないので変えない。

## 実装しないこと

- `vincentlu/alloy.nvim` を入れること。要るのは文法と `highlights.scm` で、ファイルタイプの判定は [ADR 0104](0104-nvim-alloy-lsp.md) で足してある。
- `runoshun/vim-alloy` (正規表現の syntax)。tree-sitter の文法のほうが新しく、Alloy 6 を扱う。
- Alloy のインデント (`indents.scm`) を自分で書くこと。

## テスト設計

設定の変更なので、CI の自動テストは書かない。実装の前に次を実行して今の値を確かめ、実装の後にもう一度実行して確かめる (nvim を `--headless` で起動する。[ADR 0100](0100-nvim-hpeg-golem-emet-highlight-and-emet-lsp.md) と同じやり方)。

- `require("nvim-treesitter").install({ "alloy" })` で文法が入り、`vim.treesitter.language.add("alloy")` が通る (実装の前は失敗する)。
- スクラッチパッドの `.als` を開くと、`vim.treesitter.highlighter.active` にそのバッファが入る (実装の前は入らない)。
- 次の位置の capture (`vim.treesitter.get_captures_at_pos`) が、`highlights.scm` のとおりになる: `sig` (`keyword`)、シグネチャの名前 (`type.definition`)、
  `pred` の名前 (`function`)、`always` (`keyword.operator`)、コメント (`comment`)。
- Alloy の jar に入っている例のモデル (`models/` の下の `.als`) を構文木にして、`ERROR` の節を含むファイルの数を数え、ADR に書く。
- LSP が付いた後も、色付けが続く。
- 本人が確かめる: Ghostty の nvim で `.als` を開くと、キーワード・型・コメントに色が付く。

## 結果

nvim を `--headless` で起動し、スクラッチパッドの `.als` (コメント、`sig Node { var next: lone Node }`、`pred step[n: Node] { always some n.next }`) を開いた。
文法は `require("nvim-treesitter").install({ "alloy" })` で入れた (取得・ビルド・`queries/alloy/highlights.scm` の配置まで通った)。

| 項目 | 実装の前 | 実装の後 |
| --- | --- | --- |
| `vim.treesitter.language.add("alloy")` | `nil` | `true` |
| 色付け (`vim.treesitter.highlighter.active`) | 無し | 有り。LSP (`alloy_ls`) が付いた後も続く |
| コメント | 無し | `comment` |
| `sig`・`var`・`pred` | 無し | `keyword` |
| シグネチャの名前 `Node` | 無し | `type.definition` |
| `pred` の名前 `step` | 無し | `function` |
| `always` | 無し | `keyword.operator` |

Alloy の jar (`alloy6.jar`) の `models/` の下の 94 の `.als` を構文木にすると、8 つが `ERROR` の節を含んだ。最初の `ERROR` の行は次のとおり (`sequniv.als` は `ERROR` の節を拾えず、行を出していない)。
文法が扱わない書き方は、間に空白のある多重度の矢印 (`Key one->Time`、`Room lone-> Key`)、モジュールで修飾した関数の呼び出し (`fun/sub`)、引数のある `let` (`let dynamic[x] = ...`) である。
`ERROR` は、その周りの色付けが崩れるだけで、ほかの行は色が付く。

- `book/appendixE/p300-hotel.als`・`p303-hotel.als`・`p306-hotel.als` の 12 行目: `key: Key one->Time`
- `book/chapter6/hotel1.als`・`hotel2.als` の 16 行目: `Room<:keys   in   Room lone-> Key`
- `util/integer.als` の 64 行目: `fun signum [n: Int] : Int { n<0 => (0 fun/sub 1) else (n>0 => 1 else 0) }`
- `util/time.als` の 5 行目: `let dynamic[x] = x one-> Time`
- `util/sequniv.als`

インデント: `sig A {` と `  f: one A` の 2 行目で `o` を押すと、新しい行は 0 桁目から始まった (`indentexpr` は nvim-treesitter のまま)。
「トレードオフ」のとおり、直すなら別の ADR にする。

## トレードオフ

- コミットを固定するので、文法が直っても自動では上がらない。上げるときは `revision` を書きかえる。
- 自分のリポジトリでない C のコード (`src/parser.c`) を、nvim-treesitter が手元でビルドする。コミットを固定し、上げるときに差分を読む。
- `indents.scm` が無いので、インデントは nvim-treesitter の `indentexpr` に任せる。おかしければ、`alloy` では `indentexpr` を外す別の ADR を書く。

## 参考文献

- https://github.com/vincentlu/tree-sitter-alloy (ghq で取得、`7bcc865`): `README.md`、`tree-sitter.json`、`queries/highlights.scm`、`test/corpus/`
- https://github.com/vincentlu/alloy.nvim、https://github.com/fore-stun/tree-sitter-alloy、https://github.com/bakaq/tree-sitter-alloy6、https://github.com/runoshun/vim-alloy (ghq で取得)
- nvim-treesitter (main) の `lua/nvim-treesitter/install.lua`
- nvim-lspconfig の `lsp/alloy_ls.lua`
