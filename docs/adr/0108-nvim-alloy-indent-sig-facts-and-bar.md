# ADR 0108: nvim の Alloy のインデントで、シグネチャの制約と `|` の次の行を直す

ステータス: 採択

## 文脈

[ADR 0107](0107-nvim-alloy-indent.md) で、`nvim/queries/alloy/indents.scm` を書いて Alloy のインデントをした。その「結果」に、次の 2 つが残った。

- シグネチャの制約 (`sig A { ... } { ... }` の後ろの `{ ... }`) の中が 2 段下がる。
- 行の終わりの `|` の次の行 (`all x: s.context |` の続き) が下がらない。

本人から、この 2 つも直すよう頼まれた。調べたことは次のとおり。

- 文法 (`vincentlu/tree-sitter-alloy`、`7bcc865`) の `src/grammar.json` と、手元で入れた文法で `.als` を構文木にした結果:
  - `sig_decl` は、`"{"`・`sig_body` (フィールド)・`"}"` の後に、シグネチャの制約の `block_expression` を子として持てる。
  - `|` を持つ規則は、`quantified_expression` (`all x: A | ...`。`all x: A { ... }` の形も同じ節)・`let_expression` (`let x = e | ...`)・`set_comprehension` の 3 つ。`set_comprehension` は [ADR 0107](0107-nvim-alloy-indent.md) で下げている。
- nvim-treesitter (main) の `lua/nvim-treesitter/indent.lua`:
  - 行のインデントは、その行の節から親へたどり、`@indent.begin` の節ごとに 1 段足す。同じ行から始まる節は 1 回だけ数える。
  - `@indent.dedent` の節は、その節が始まる行でなければ 1 段引く。
  - シグネチャの制約の中の行は、`block_expression` と `sig_decl` の 2 つの `@indent.begin` が別の行から始まるので、2 段になる。
- 試した query (今の `indents.scm` に次を足し、スクラッチパッドの `runtimepath` に置いた):

  ```scheme
  (sig_decl
    (block_expression) @indent.dedent)

  [
    (quantified_expression)
    (let_expression)
  ] @indent.begin
  ```

  nvim を `--headless` で起動し、カーソルの行で `o` を押して打った行は次のとおり (今 → 試した query)。

  | 場合 | 今 | 試した query |
  | --- | --- | --- |
  | `sig A {` / `} {` / `}` の 2 行目 | 4 桁目 | 2 桁目 |
  | `sig A {` / `} {` / `  some f` / `}` の 3 行目で `}` | 2 桁目 | 0 桁目 |
  | `pred p {` / `  all x: A \|` / `}` の 2 行目 | 2 桁目 | 4 桁目 |
  | `pred p {` / `  let y = A \|` / `}` の 2 行目 | 2 桁目 | 4 桁目 |
  | `  all x: A \| some x` (1 行) の次 | 2 桁目 | 2 桁目 |
  | `  all x: A \| {` / `  }` の中、`all x: A {` / `  }` の中 | 4 桁目 | 4 桁目 (3 段にならない) |
  | `  all x: A \|` / `    some x` の次 | 2 桁目 | 4 桁目 |
  | [ADR 0107](0107-nvim-alloy-indent.md) の `sig`・`pred`・`enum`・内包表記・`}` の場合 | (変わらない) | (変わらない) |

  最後から 2 つ目の行のように、`|` の本体の次の行は、本体の続きとみなして 4 桁目になる。書いた後に `gg=G` でインデントし直すと、
  次の式は `  some A` (2 桁目) に戻る (`pred p {` / `all x: A |` / `some x` / `some A` / ... / `}` の全体をインデントし直して確かめた)。
- Alloy の jar の `models/` の下の例のうち `ERROR` の節の無い 86 のファイルを `gg=G` でインデントし直すと、変わった空でない行は 1294 行 (今) から 1021 行 (試した query) に減った。

## 実装すること

- `nvim/queries/alloy/indents.scm` に、上の「試した query」の 2 つを足す。注釈に、シグネチャの制約を 1 段にすることと、`|` の次の行を下げることと、この ADR を書く。
- `docs/specifications.md` の Alloy のインデントの記述に書く。README は変えない。

## 実装しないこと

- `|` の本体の次の行を、打っている途中で 2 桁目に戻すこと。打っている行は、前の行の続きか次の式かが構文木でまだ決まらない。`<C-d>` で戻すか、後で `=` でインデントし直す。
- 演算子 (`and`・`=>` など) で終わる行の次の行を下げること。

## テスト設計

設定の変更なので、CI の自動テストは書かない。実装の後に、上の「文脈」の表と同じ操作をスクラッチパッドの `runtimepath` を使わずに (dotfiles の `nvim/queries/alloy/indents.scm` で) 行い、右の列と同じになることを確かめる。

- 上の表の場合すべて。
- 上の全体をインデントし直す例。
- Alloy の jar の例を `gg=G` でインデントし直して、変わった行の数が 1021 になる。
- 本人が確かめる: Ghostty の nvim で、シグネチャの制約と `|` の次の行を書く。

## 結果

dotfiles の `nvim/queries/alloy/indents.scm` に足した後、スクラッチパッドの `runtimepath` を使わずに同じ操作をした。

- 「文脈」の表の場合は、すべて右の列 (試した query) と同じになった。
- 全体をインデントし直す例は、`  some A` (2 桁目)・`  let z = A |` の次の `    some z` (4 桁目)・シグネチャの制約の中の `  some f` (2 桁目) になった。
- Alloy の jar の例 (86 のファイル、6512 行) を `gg=G` でインデントし直して変わった空でない行は、1021 行だった。

## トレードオフ

- `|` の本体を書いた次の行は、本体の続きの深さ (1 段下) から始まる。次の式を書くときは、手で戻す。
- [ADR 0107](0107-nvim-alloy-indent.md) と同じく、文法の節の名前 (`quantified_expression`・`let_expression`・`block_expression`) を使うので、文法を上げて名前が変わると直す。

## 参考文献

- https://github.com/vincentlu/tree-sitter-alloy (ghq で取得、`7bcc865`): `src/grammar.json`
- nvim-treesitter (main) の `lua/nvim-treesitter/indent.lua`
- スクラッチパッドで動かした nvim の結果
