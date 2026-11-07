# ADR 0107: nvim で Alloy のインデントを tree-sitter の indents.scm で行う

ステータス: 採択

## 文脈

[ADR 0106](0106-nvim-alloy-highlight.md) で、`.als` を tree-sitter の文法 `alloy` (`vincentlu/tree-sitter-alloy`) で色付けした。
この文法には `indents.scm` が無い。`nvim/lua/plugins/treesitter.lua` は、文法のあるバッファの `indentexpr` を nvim-treesitter の `indentexpr()` にするので、
`sig A {` と `  f: one A` の 2 行目で `o` を押すと、新しい行が 0 桁目から始まる ([ADR 0106](0106-nvim-alloy-highlight.md) の「結果」)。本人から、インデントも直すよう頼まれた。

調べたことは次のとおり。

- 文法 (`src/grammar.json`) で `{` を持つ規則は、`sig_decl` (フィールドの並び)・`enum_decl`・`block_expression` (`fact`・`pred`・`fun`・`assert` の本体や、`{ ... }` の式)・`set_comprehension` の 4 つ。
  `sig_decl` は、フィールドの `{ ... }` の後に、シグネチャの制約の `block_expression` を続けて持てる。
- nvim-treesitter の `indentexpr()` は、`indents` の query の `@indent.begin` (中の行を 1 段下げる)・`@indent.branch` (閉じかっこの行を戻す)・`@indent.end` などで決める。
  nvim-treesitter の Go などの `indents.scm` は、`{ ... }` を持つ節を `@indent.begin` に、`"}"` を `@indent.branch` にしている。
- query は `runtimepath` の `queries/<言語>/` から読まれる。dotfiles の `nvim/` は `~/.config/nvim` で、`runtimepath` にある。
- nvim-autopairs が入っている (`nvim/lua/plugins/editor.lua`)。`{` を打つと `}` が足されるので、`{` の後で改行したとき、構文木は閉じた `{ ... }` になる。
- インデントの幅は `shiftwidth = 2`・`expandtab` (`nvim/lua/config/options.lua`)。

ほかの直し方は次のとおり。

| 直し方 | `{` の後の行 | `}` の行 | ほかに起きること |
| --- | --- | --- | --- |
| `indents.scm` を dotfiles に書く (この ADR) | 1 段下がる | 戻る | 文法の節の名前が変わると直す |
| `alloy` で `indentexpr` を外す (`autoindent` だけ) | 前の行と同じ | 前の行と同じ | 1 段下げるのは手で行う |
| `smartindent` | 1 段下がる | 戻る | 行の頭に `#` (Alloy の要素の数) を打つと、インデントが消える |
| `cindent` | 1 段下がる | 戻る | `;` で終わらない行を続きの行とみなし、さらに下げる。Alloy の行はふつう `;` で終わらない |

## 実装すること

- `nvim/queries/alloy/indents.scm` を足す。
  - `sig_decl`・`enum_decl`・`block_expression`・`set_comprehension` を `@indent.begin` にする。
  - それぞれの `"}"` を `@indent.branch` と `@indent.end` にする。
  - ブロックのコメント (`block_comment`) は `@indent.auto` にする (前の行に合わせる)。
  - 先頭の注釈に、文法 `vincentlu/tree-sitter-alloy` に `indents.scm` が無いことと、この ADR を書く。
- `docs/specifications.md` の Alloy の色付けの記述に書く。README は nvim の言語ごとの設定を持たないので変えない。

## 実装しないこと

- `vincentlu/tree-sitter-alloy` に `indents.scm` を送ること。手元で使ってみてから考える。
- `[ ... ]` (述語の引数) と `( ... )` の中の改行のインデント。
- `sig_decl` のフィールドの後のシグネチャの制約 (`sig A { ... } { ... }`) の中のインデント。`sig_decl` の中の `block_expression` なので 2 段下がるかもしれない。結果に書き、おかしければ別の ADR で直す。

## テスト設計

設定の変更なので、CI の自動テストは書かない。実装の前に次を実行して今の値を確かめ、実装の後にもう一度実行して確かめる
(nvim を `--headless` で起動し、スクラッチパッドの `.als` で、nvim-autopairs と同じく閉じかっこのある行の中でキーを送る)。

- `sig A {` と `  f: one A` と `}` の 2 行目で `o` を押して打った行が 2 桁目から始まる (実装の前は 0 桁目)。
- `pred p {` と `}` の間で改行して打った行が 2 桁目から始まる。その中の `all x: A | {` と `}` の間ではさらに 2 桁下がる (4 桁目)。
- `fact {`・`enum E {`・`{ x: A | ... }` の中も同じ。
- `}` を打った行が、開いた行のインデントに戻る。
- 既存のファイル (Alloy の jar の `models/` の下の例) を `gg=G` でインデントし直して、変わった行の数を結果に書く (`ERROR` の節のあるファイルは除く)。
- 本人が確かめる: Ghostty の nvim で `.als` を書くと、`{` の後で 1 段下がり、`}` で戻る。

## 結果

nvim を `--headless` で起動し、ファイルタイプ `alloy` のバッファで、カーソルの行で `o` を押して `x` (`close` は `}`) を打った。打った行は次のとおり (`shiftwidth = 2`)。

| 場合 | 初めの行 | 実装の前 | 実装の後 |
| --- | --- | --- | --- |
| `sig` | `sig A {` / `  f: one A` / `}` の 2 行目 | `x` (0 桁目) | `  x` |
| `pred` | `pred p {` / `}` の 1 行目 | `x` | `  x` |
| 入れ子 | `pred p {` / `  all x: A \| {` / `  }` / `}` の 2 行目 | `x` | `    x` |
| `fact` | `fact {` / `}` の 1 行目 | `x` | `  x` |
| `enum` | `enum E {` / `}` の 1 行目 | `x` | `  x` |
| 内包表記 | `fun f: set A {` / `  { x: A \|` / `  }` / `}` の 2 行目 | `x` | `    x` |
| `}` を打つ | `pred p {` / `  some A` / `}` の 2 行目 | `}` | `}` (0 桁目。開いた行に戻る) |
| シグネチャの制約 | `sig A {` / `} {` / `}` の 2 行目 | `x` | `    x` (2 段下がる) |

シグネチャの制約 (`sig A { ... } { ... }`) の中は、「実装しないこと」で心配したとおり 2 段下がった。直すなら別の ADR にする。

Alloy の jar の `models/` の下の例のうち、`ERROR` の節の無い 86 のファイル (6512 行) を `gg=G` でインデントし直すと、空でない 1294 行が変わった (タブは 2 桁として比べた)。
変わった行の多い `numbering.als` の差分を読むと、多くは書き方の違いだった (例は 1 段を 4 桁にし、`}` を中の行と同じ深さに置く)。
ほかに、行の終わりの `|` の次の行 (`all x: s.context |` の続き) は下がらない。これも、直すなら別の ADR にする。

## トレードオフ

- 文法の節の名前を dotfiles の query が使うので、文法の `revision` を上げて節の名前が変わると、`indents.scm` も直す。上げるときに、上のテストをもう一度行う。
- 書きかけで構文木が `ERROR` になる所では、インデントが崩れることがある。

## 参考文献

- https://github.com/vincentlu/tree-sitter-alloy (ghq で取得、`7bcc865`): `src/grammar.json`
- nvim-treesitter (main) の `runtime/queries/go/indents.scm`、`lua/nvim-treesitter/indent.lua`、`:h treesitter-query`
- dotfiles の `nvim/lua/plugins/treesitter.lua`・`nvim/lua/plugins/editor.lua`・`nvim/lua/config/options.lua`
