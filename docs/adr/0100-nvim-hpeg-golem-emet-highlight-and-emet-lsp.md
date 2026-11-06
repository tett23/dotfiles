# ADR 0100: nvim で .hpeg・.gm・.emet を tree-sitter で色付けし、.emet でも Golem の LSP を使う

ステータス: 採択

## 文脈

本人から、peg-hs と Golem の `.hpeg`・`.gm`・`.emet` のシンタックスハイライトと LSP ができたので、nvim に入れるよう頼まれた。
LSP は、`.gm` を [ADR 0092](0092-nvim-golem-lsp.md) で、`.hpeg` を [ADR 0099](0099-nvim-peg-hs-lsp.md) で入れてある。
この ADR の最初の草稿を書いた後、本人が peg-hs と Golem の README に、Neovim で GitHub から文法を入れる例を足した。この版は、その更新を読んで書き直したものである。

調べたことは次のとおり。

### peg-hs (ghq で取得、`d8b4e3c`)

- `editors/tree-sitter-hpeg/` に tree-sitter の文法がある (`grammar.js`、生成した `src/parser.c`、外部のスキャナー `src/scanner.c`)。
  問い合わせは `queries/` に `highlights.scm`・`injections.scm`・`locals.scm`・`folds.scm`・`indents.scm` がある。
  `injections.scm` は、文法の中の Haskell の断片 (verbatim ブロック、型、アクション) を Haskell として色付けする。
- peg-hs の `docs/adr/0074-neovim-tree-sitter-from-github.md` (採択) と、それを実装した `README.ja.md` の「Neovim (未確認)」の「ハイライト」:
  - nvim-treesitter (main ブランチ) の `User TSUpdate` で、`install_info` に `url = 'https://github.com/tett23/peg-hs'`・`location = 'editors/tree-sitter-hpeg'`・
    `queries = 'editors/tree-sitter-hpeg/queries'`・`revision = 'v0.1.0-rc3'` を書き、`:TSInstall hpeg` で入れる。
  - `revision` にリリースのタグを書くと、その版の文法を入れ、タグを変えるまで `:TSUpdate` で入れ直さない。言語サーバー (`peg-hs lsp`) と同じ版のタグを書くと、ハイライトと diagnostics の記法の版がそろう。
    `revision` を消すと `main` の先頭を入れ、`:TSUpdate` のたびに入れ直す。
  - Haskell の断片に色を付けるには、nvim-treesitter の `haskell` のパーサーも要る。
- GitHub の Releases の最新は `v0.1.0-rc3` (2026-11-06 01:40、macOS arm64 のアーカイブがある)。

### Golem (ghq で取得、`a5e7bae3`)

- Golem の `docs/adr/0170-emet-editor-support.md` (採択) で、`.gm` と `.emet` の tree-sitter の文法 (`tools/editors/tree-sitter-golem/`・`tools/editors/tree-sitter-emet/`。
  ファイルタイプ `golem`・`emet` の `queries/highlights.scm` を持つ) と、`.emet` の LSP の semantic tokens・アウトライン・名前の変更・局所の名前の型のホバーを決めた。
- Golem の `docs/adr/0171-neovim-setup-from-github-and-emet-lsp.md` (採択) と、それを実装した `tools/editors/README.md` の「Neovim」・`manual/chapters/09-editor.gm`:
  - `User TSUpdate` で `golem` と `emet` の `install_info` に、`url = 'https://github.com/tett23/golem'`、`location = 'tools/editors/tree-sitter-<名前>'`、
    `queries = 'tools/editors/tree-sitter-<名前>/queries'` を書き、`:TSInstall golem emet` で入れる。`revision` は書いていない (`main` の先頭)。
  - コンパイルには tree-sitter の CLI と C コンパイラーが要る。
  - `vim.filetype.add({ extension = { gm = 'golem', emet = 'emet' } })`。LSP の例の `filetypes` は `{ "golem", "emet", "toml" }`。
- GitHub の Releases の最新は `v0.1.0-rc3` (2026-10-24) で、ADR 0170 より前である。

### nvim-treesitter (main ブランチ、`e289100`)

- `lua/nvim-treesitter/install.lua`: `url` のときは GitHub の tarball を落とし、`location` で C をコンパイルし、`queries` をリポジトリのルートからのパスとして写す。
  `revision` が無いと `branch` か `main` を落とし、`:TSUpdate` のたびに入れ直す (`needs_update`)。

### mise (2026.10.17)

- 既定で、公開から 24 時間たたない版を `latest` に選ばない (mise のリポジトリの `docs/security.md` の「Minimum release age」。github バックエンドも対象)。
  そのため、2026-11-06 11:52 の `mise ls-remote 'github:tett23/peg-hs[prerelease=true]'` は `0.1.0-rc2` までだった。その後、本人が rc3 を入れ、今の `peg-hs` は mise の `0.1.0-rc3` である (`mise ls github:tett23/peg-hs`)。

### 試した結果

- nvim-treesitter の `install_dir` をスクラッチパッドにし、上の `url`・`location`・`queries` (`revision` なし) で `hpeg`・`golem`・`emet` と `haskell` を入れた。4 つで 6.1 秒かかった。
- `vim.treesitter.get_captures_at_pos` で、言語ごとに次の捕捉が付いた。どのファイルも構文の誤りは無い。

  | ファイル | 位置 | 捕捉 |
  | --- | --- | --- |
  | peg-hs の `packages/peg-grammar/grammar/Peg.hpeg` | `%module` | `hpeg` の `@keyword.directive` |
  | 同じ | `%{ … }%` の中の `import` | `haskell` の `@keyword.import` |
  | Golem の `emet-samples` の `text.gm` | 見出しの `#` | `golem` の `@keyword` |
  | 同じ | 見出しの文字 (`文字`) | `golem` の `@module` |
  | 同じ | `[t.mono …]` の `t.mono` | `golem` の `@function` |
  | 同じ `emet-samples` の `fn/lib.emet` | `pub` | `emet` の `@keyword` |
  | 同じ | シグネチャの関数の名前 | `emet` の `@function` |

- 手元の `~/.local/bin/golem` (2026-11-06 11:49 にビルドしたもの、`golem 0.1.0-rc3`) で、`filetypes` に `emet` を足して `fn/lib.emet` を開くと、クライアントが付き、
  `textDocument/semanticTokens/full` は 5810 個の値 (トークンごとに 5 つ)、`textDocument/documentSymbol` は 25 個を返した。

### 今の dotfiles の設定 (`nvim --headless` で確かめた)

- `.hpeg` は `hpeg`、`.gm` は `golem` のファイルタイプになるが、tree-sitter の色付けは動いていない (`vim.treesitter.highlighter.active` にバッファが無い)。`.emet` はファイルタイプが空。
- `hpeg`・`golem`・`emet`・`haskell` のパーサーは入っていない。
- Golem の LSP の `filetypes` は `golem`・`toml`。
- `nvim/lua/plugins/treesitter.lua` は、`parsers` の一覧を `require("nvim-treesitter").install` で入れ、`FileType` の自動コマンドで、パーサーのあるファイルタイプすべてに
  `vim.treesitter.start` とインデントを設定している ([ADR 0009](0009-fix-git-tmux-nvim-audit.md))。

## 実装すること

### 言語ごとに入れるもの

| 拡張子 | ファイルタイプ | tree-sitter の文法 (取得元) | 使う問い合わせ | LSP |
| --- | --- | --- | --- | --- |
| `.hpeg` | `hpeg` | `hpeg` (peg-hs の `editors/tree-sitter-hpeg`) | `highlights.scm`・`injections.scm`・`indents.scm` (`locals.scm`・`folds.scm` も入るが、設定では使わない) | `peg-hs lsp` ([ADR 0099](0099-nvim-peg-hs-lsp.md) のまま) |
| `.hpeg` の Haskell の断片 | (注入) | `haskell` (nvim-treesitter の一覧にあるもの) | nvim-treesitter の `haskell` の問い合わせ | なし |
| `.gm` | `golem` | `golem` (Golem の `tools/editors/tree-sitter-golem`) | `highlights.scm` | `golem lsp` ([ADR 0092](0092-nvim-golem-lsp.md) のまま) |
| `.emet` | `emet` (新しく足す) | `emet` (Golem の `tools/editors/tree-sitter-emet`) | `highlights.scm` | `golem lsp` (`filetypes` に `emet` を足す) |

LSP の semantic tokens を返すサーバー (`golem lsp`、`peg-hs lsp`) が付いた後は、semantic tokens の色が tree-sitter の色の上に重なる。
tree-sitter の色は、LSP が付く前と、semantic tokens の付かない部分に出る。

### 変えるファイル

- `nvim/lua/plugins/treesitter.lua`:
  - `install` を呼ぶ前に、`User TSUpdate` の自動コマンドで、`require("nvim-treesitter.parsers")` に次の 3 つを足す。peg-hs と Golem の README の例と同じ書き方にする。注釈にこの ADR を書く。

    | 言語 | `url` | `location` | `queries` |
    | --- | --- | --- | --- |
    | `hpeg` | `https://github.com/tett23/peg-hs` | `editors/tree-sitter-hpeg` | `editors/tree-sitter-hpeg/queries` |
    | `golem` | `https://github.com/tett23/golem` | `tools/editors/tree-sitter-golem` | `tools/editors/tree-sitter-golem/queries` |
    | `emet` | `https://github.com/tett23/golem` | `tools/editors/tree-sitter-emet` | `tools/editors/tree-sitter-emet/queries` |

  - 3 つとも `revision` は書かず、`main` の先頭を入れる。peg-hs の README はリリースのタグ (`revision = 'v0.1.0-rc3'`) を勧めるが、dotfiles は peg-hs を mise の `latest` で入れるので、
    タグを書くと、mise が新しい版を入れるたびに書き換えが要る (トレードオフに書く)。
  - `parsers` の一覧に `hpeg`・`golem`・`emet` と、`.hpeg` の Haskell の断片のための `haskell` を足す。
  - 色付けとインデントは、今の `FileType` の自動コマンドのまま (足す設定は無い)。
- `nvim/lua/config/autocmds.lua` の `vim.filetype.add` の `extension` に `emet = "emet"` を足す。注釈にこの ADR を書く。
- `nvim/lua/plugins/lsp.lua` の Golem の LSP の `filetypes` を `{ "golem", "emet", "toml" }` にする (Golem のマニュアルの例と同じ)。`root_markers` (`manifest.toml`) と `workspace_required` はそのまま。注釈にこの ADR を書く。
- `docs/specifications.md` の nvim の節に書く (tree-sitter の文法を GitHub から入れること、Golem の LSP が `.emet` も扱うこと)。
- `README.md` は変えない。README には、nvim の tree-sitter や LSP の節が無いため。

## 実装しないこと

- `revision` での版の固定。
- peg-hs の `folds.scm` による折り畳み (`foldmethod = "expr"`)。今の設定は、どのファイルタイプでも tree-sitter の折り畳みを使っていない。
- mise の、公開から 24 時間の制限 (`minimum_release_age`) を peg-hs で外すこと。新しい版は、制限が過ぎた後の `bin/update-mise` で入る。
- Golem と peg-hs の手元の作業コピー (ghq) を、文法の取得元にすること (`install_info.path`)。作業コピーの状態で色付けが変わるため。
- TextMate の文法 (nvim は読まない)。

## テスト設計

nvim の設定の変更なので、CI の自動テストは書かない。実装の前に次を実行して今の値を確かめ (上の「今の dotfiles の設定」の値)、実装の後にもう一度実行して確かめる。
`nvim --headless` は `--clean` を付けず、実際の設定で動かす。

- `require("nvim-treesitter").install({ "hpeg", "golem", "emet", "haskell" }):wait()` を実行し、パーサーが `~/.local/share/nvim/site/parser/` に、問い合わせが `~/.local/share/nvim/site/queries/` に入ること。
- peg-hs の `Peg.hpeg`、Golem の `emet-samples` の `text.gm` と `fn/lib.emet` (スクラッチパッドに写したもの) を開き:
  - ファイルタイプが、`hpeg`・`golem`・`emet` であること (`.emet` は、実装の前は空)。
  - `vim.treesitter.highlighter.active` に、そのバッファがあること (実装の前は無い)。
  - `vim.treesitter.language.add` が、`hpeg`・`golem`・`emet`・`haskell` で真であること (実装の前は偽)。
  - `vim.lsp.config.golem.filetypes` が `golem`・`emet`・`toml` であること (実装の前は `golem`・`toml`)。
- 言語ごとに、上の「試した結果」の表の位置で、同じ捕捉が付くこと (`vim.treesitter.get_captures_at_pos`)。
  本人から「`.gm` に tree-sitter の色が付かない疑いがある」と聞いたので、`.gm` では、Golem の LSP が付いて semantic tokens が返った後も、
  `vim.treesitter.highlighter.active` にバッファが残ることも確かめる。
- `manifest.toml` のあるフォルダの `.emet` で、Golem の LSP のクライアントが付き、semantic tokens と `documentSymbol` が空でないこと。
- 本人が確かめる: Ghostty の nvim で `.hpeg`・`.gm`・`.emet` を開き、LSP が動く前から色が付く。`.hpeg` の Haskell の断片にも Haskell の色が付く。

## トレードオフ

- `revision` を書かないので、`:TSUpdate` のたびに 3 つを入れ直す (lazy.nvim で nvim-treesitter を更新したときにも、`build = ":TSUpdate"` で動く)。手元では `haskell` を含めた 4 つで 6 秒ほどかかる。
  Golem のリポジトリは、文法のためだけに 2 回、全体の tarball を落とす。
- `main` の先頭を入れるので、文法の壊れた変更もそのまま入る。
- peg-hs では、`main` の文法が、mise で入れた `peg-hs lsp` の版より新しいことがある (今は文法が `main` の `d8b4e3c`、LSP が rc3。`v0.1.0-rc3` から `d8b4e3c` までに `editors/tree-sitter-hpeg` の変更は無いので、今はずれていない)。peg-hs の README が言うとおり、ハイライトと diagnostics の記法の版がずれうる。
  版をそろえたくなったら、別の ADR で `revision` を決める。
- Golem の文法は、Golem の構文解析 (peg-hs) とは別に書いたもので、細部が一致しないことがある (Golem の ADR 0170 のトレードオフ)。LSP の semantic tokens が動けば、そちらの色が優先される。

## 参考文献

- peg-hs のリポジトリ (ghq で取得、`d8b4e3c`): `README.ja.md` の「Neovim (未確認)」、`docs/adr/0074-neovim-tree-sitter-from-github.md`、`editors/tree-sitter-hpeg/queries/injections.scm`
- Golem のリポジトリ (ghq で取得、`a5e7bae3`): `docs/adr/0170-emet-editor-support.md`、`docs/adr/0171-neovim-setup-from-github-and-emet-lsp.md`、`tools/editors/README.md`、`manual/chapters/09-editor.gm`
- nvim-treesitter (main ブランチ、`e289100`): `README.md` の「Adding custom languages」、`lua/nvim-treesitter/install.lua`
- mise のリポジトリ (ghq で取得、`e6cac97`): `docs/security.md` の「Minimum release age」、`docs/cache-behavior.md`
- peg-hs と Golem の GitHub の Releases
