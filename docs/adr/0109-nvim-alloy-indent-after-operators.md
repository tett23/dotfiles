# ADR 0109: nvim の Alloy のインデントで、`and` や `=>` で終わる行の次を下げる

ステータス: 採択

## 文脈

[ADR 0108](0108-nvim-alloy-indent-sig-facts-and-bar.md) で、行の終わりの `|` の次の行を下げた。その「実装しないこと」で、演算子 (`and`・`=>` など) で終わる行の次の行は下げないとした。
本人から、`and` や `=>` で終わる行の次も下げるよう頼まれた。

調べたことは次のとおり。

- 文法 (`vincentlu/tree-sitter-alloy`、`7bcc865`) の `src/grammar.json` で、論理の 2 項演算子を持つ規則は次のとおり。
  - `and_expression` (`and`・`&&`)、`or_expression` (`or`・`||`)、`iff_expression` (`iff`・`<=>`)
  - `implies_expression` (`implies`・`=>`。`else` も持つ)
  - `temporal_binary_expression` (`until`・`since`・`releases`・`triggered`)
- 手元で入れた文法で構文木にすると:
  - 書き終えた `some A and` / `some B` は `and_expression` になる。
  - 打っている途中の `some A and` (次の行がまだ無い) は、`multiplicity_expression` の後に、`and` だけを持つ `ERROR` の節になる。`=>` も同じ。
    `else` まで打った `some A =>` / `some B` / `else` は、`implies_expression` の後に空の `ERROR` になる。
  - 一方、`all x: A |` は `quantified_expression` の本体が `MISSING` の節になり、`ERROR` にならない ([ADR 0108](0108-nvim-alloy-indent-sig-facts-and-bar.md) で下がったのはこのため)。
- nvim-treesitter の `indent.lua` は、1 行の節でも `@indent.begin` に `indent.immediate` を付けると、次の行を下げる。Python の `indents.scm` は、`(ERROR "try" . ":")` に `indent.immediate` を付けて、打っている途中の行を下げている。
- 試した query (今の `indents.scm` に次を足し、スクラッチパッドの `runtimepath` に置いた):

  ```scheme
  [
    (and_expression)
    (or_expression)
    (implies_expression)
    (iff_expression)
    (temporal_binary_expression)
  ] @indent.begin

  (implies_expression
    "else" @indent.branch)

  ((ERROR
    .
    ["and" "&&" "or" "||" "implies" "=>" "iff" "<=>" "until" "since" "releases" "triggered" "else"]
    .) @indent.begin
    (#set! indent.immediate 1))

  (implies_expression
    "else"
    .
    (block_expression) @indent.dedent)
  ```

  nvim を `--headless` で起動し、カーソルの行で `o` を押して打った行は次のとおり (今 → 試した query。`pred p {` の中)。

  | 場合 | 今 | 試した query |
  | --- | --- | --- |
  | `  some A and` の次 (`&&`・`or`・`=>`・`implies`・`<=>`・`until` も同じ) | 2 桁目 | 4 桁目 |
  | `  some A and some B` (1 行) の次 | 2 桁目 | 2 桁目 |
  | `  some A and` / `    some B and` の次 | 2 桁目 | 4 桁目 |
  | `  all x: A \| some x and` の次 | 2 桁目 | 4 桁目 |
  | `  some A => {` / `  }` の中 | 4 桁目 | 4 桁目 |
  | `  some A =>` / `    some B` の次で `else` を打つ | 2 桁目 | 2 桁目 |
  | `  some A =>` / `    some B` / `  else` の次 | 2 桁目 | 4 桁目 |
  | `  some A => {` / `    some B` / `  } else {` / `  }` の中 | 4 桁目 | 4 桁目 |
  | [ADR 0107](0107-nvim-alloy-indent.md)・0108 の場合 (`sig`・`all x: A \|` など) | (変わらない) | (変わらない) |

  `implies_expression "else" . (block_expression) @indent.dedent` が無いと、`} else {` の中が 6 桁目になった (`else` の後のブロックと `implies_expression` の 2 つで下がるため)。

  `pred p {` / `some A and` / `some B` / `some C =>` / `some D` / `else` / `some E` / `some F or some G` / `all x: A |` / `some x` / `}` を `gg=G` でインデントし直すと、
  `  some A and` / `    some B` / `  some C =>` / `    some D` / `  else` / `    some E` / `  some F or some G` / `  all x: A |` / `    some x` になった。
- Alloy の jar の `models/` の下の例 (`ERROR` の節の無い 86 のファイル、6512 行) を `gg=G` でインデントし直して変わった空でない行は、1021 行 (今) から 1049 行 (試した query) になった。
  `dijkstra.als` の差分を読むと、例が下げていない `Initial[so/first] &&` の次の行が下がり、`||` で始まる行が 1 段深くなった。書き方の違いで、この ADR の決まりのとおりである。

## 実装すること

- `nvim/queries/alloy/indents.scm` に、上の「試した query」の 4 つを足す。注釈に、演算子で終わる行の次を下げることと、打っている途中は `ERROR` の節になるので `indent.immediate` で下げることと、この ADR を書く。
- `docs/specifications.md` の Alloy のインデントの記述に書く。README は変えない。

## 実装しないこと

- 演算子で始まる行 (`|| ...` のように、前の行の続きを演算子から書く形) を特に扱うこと。
- 比べる演算子 (`=`・`in` など) や、集合の演算子 (`+`・`&`・`.` など) で終わる行の次を下げること。
- `|` と同じく、演算子の右を書いた次の行を、打っている途中で戻すこと ([ADR 0108](0108-nvim-alloy-indent-sig-facts-and-bar.md) のトレードオフと同じ)。

## テスト設計

設定の変更なので、CI の自動テストは書かない。実装の後に、上の「文脈」の表と同じ操作をスクラッチパッドの `runtimepath` を使わずに (dotfiles の `nvim/queries/alloy/indents.scm` で) 行い、右の列と同じになることを確かめる。

- 上の表の場合すべて。
- 上の全体をインデントし直す例。
- Alloy の jar の例を `gg=G` でインデントし直して、変わった行の数が 1049 になる。
- 本人が確かめる: Ghostty の nvim で、`and` や `=>` で終わる行を書いて改行する。

## 結果

dotfiles の `nvim/queries/alloy/indents.scm` に足した後、スクラッチパッドの `runtimepath` を使わずに同じ操作をした。

- 「文脈」の表の場合は、すべて右の列 (試した query) と同じになった。[ADR 0107](0107-nvim-alloy-indent.md)・0108 の場合も変わらなかった。
- 全体をインデントし直す例は、「文脈」に書いたとおりになった。`some A or` / `some B and` / `some C` は、`some C` が 6 桁目になった (「トレードオフ」)。
- Alloy の jar の例 (86 のファイル、6512 行) を `gg=G` でインデントし直して変わった空でない行は、1049 行だった。

## トレードオフ

- `or` と `and` を混ぜて行を分けると、節が入れ子になるので 2 段下がる (`some A or` / `some B and` / `some C` を `gg=G` でインデントし直すと、`some C` は 6 桁目になった)。
- 打っている途中の形 (`ERROR` の中身) は、文法の誤りの回復のしかたに頼る。文法を上げると変わることがあるので、上げるときに上のテストをもう一度行う。

## 参考文献

- https://github.com/vincentlu/tree-sitter-alloy (ghq で取得、`7bcc865`): `src/grammar.json`
- nvim-treesitter (main) の `lua/nvim-treesitter/indent.lua`、`runtime/queries/python/indents.scm`
- スクラッチパッドで動かした nvim の結果
