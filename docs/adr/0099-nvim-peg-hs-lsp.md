# ADR 0099: nvim で peg-hs の LSP サーバーを使う

ステータス: 採択

## 文脈

本人から、peg-hs (https://github.com/tett23/peg-hs) の LSP サーバーを nvim に入れるよう頼まれた。peg-hs は本人が作っている、Haskell の PEG パーサーの生成器である。

調べたことは次のとおり。

- peg-hs のリポジトリ (ghq で取得、`d89d8e1`):
  - 文法ファイルの拡張子は `.hpeg`、エディタの言語の名前は `hpeg` (peg-hs の `docs/specifications.md`、`docs/adr/0050-hpeg-extension.md`)。
  - `peg-hs lsp` が、標準入出力で LSP サーバーを動かす (peg-hs の `docs/adr/0035-language-server.md`)。diagnostics (構文の誤り、静的検査、lint の警告)、フォーマット、semantic tokens、定義への移動、参照の検索、hover、ドキュメントシンボルを返す。名前の変更・補完・コードアクションは無い。
  - `README.ja.md` の「Neovim (未確認)」の節は、`vim.filetype.add({ extension = { hpeg = 'hpeg' } })` でファイルタイプを登録し、
    `vim.lsp.config('peg_hs', { cmd = { 'peg-hs', 'lsp' }, filetypes = { 'hpeg' }, root_markers = { '.git' } })` と `vim.lsp.enable('peg_hs')` で有効にする例を示す。
  - LSP サーバーと nvim-lint の両方で `peg-hs lint` を動かすと、同じ警告が二重に出る、とある。
- 手元の `~/.local/bin/peg-hs` は 2026-10-13 02:58 のもので、サブコマンドが無く (`peg-hs --help` は `usage: peg-hs INPUT.peg [-o OUTPUT.hs] ...`)、`lsp` を持たない。
- GitHub の Releases は `v0.1.0-rc1` と `v0.1.0-rc2` だけで、どちらも pre-release である。`v0.1.0-rc2` には `peg-hs-0.1.0-rc2-aarch64-macos.tar.gz` がある。
- mise (2026.10.17) の github バックエンド:
  - `mise ls-remote github:tett23/peg-hs` は何も返さない。pre-release だけのリポジトリなので、`latest` では入らない。
  - mise のドキュメント (`docs/dev-tools/backends/github.md`) によると、既定では pre-release を `ls-remote`・`latest` から外し、`prerelease = true` で含める。
  - `mise latest 'github:tett23/peg-hs[prerelease=true]'` は `0.1.0-rc2` を返した。
  - `mise exec github:tett23/peg-hs@0.1.0-rc2` で入れた `peg-hs` は、`gen`・`fmt`・`lint`・`label`・`lsp`・`parse`・`help` のサブコマンドを持つ。
- PATH は mise が `~/.local/bin` より先である ([ADR 0023](0023-fix-remaining-audit-items-2.md))。mise で入れれば、古い `~/.local/bin/peg-hs` より先に引かれる。
- 今の nvim は、`.hpeg` のファイルタイプを判定しない (`nvim --headless t.hpeg` の `filetype` は空)。`peg_hs` の LSP の設定も無い。
- 保存のときのフォーマットは conform で、`lsp_format = "fallback"` にしている ([ADR 0055](0055-improvements-2026-10-13.md))。conform に `hpeg` のフォーマッターが無いので、LSP サーバーを付ければ、保存のたびに `peg-hs lsp` のフォーマットが動く。
- mason の外の LSP サーバーは、Golem と同じく `vim.lsp.config` と `vim.lsp.enable` で有効にしている ([ADR 0092](0092-nvim-golem-lsp.md))。

## 実装すること

- `mise/config.toml` の自作のツールの並び (rust より前) に、`"github:tett23/peg-hs" = { version = "latest", prerelease = true }` を足す。
  注釈に、この ADR と、リリースが pre-release だけなので `prerelease = true` が要ることを書く。
- `dependencies.md` の「自作のツール」に peg-hs を足す (github バックエンドで latest、pre-release も含める)。
- `nvim/lua/config/autocmds.lua` の `vim.filetype.add` の `extension` に `hpeg = "hpeg"` を足す。注釈にこの ADR を書く。
- `nvim/lua/plugins/lsp.lua` の Golem の設定の隣に、peg-hs の LSP サーバーを足す。

  ```lua
  vim.lsp.config("peg_hs", {
    cmd = { "peg-hs", "lsp" },
    filetypes = { "hpeg" },
    root_markers = { ".git" },
  })
  vim.lsp.enable("peg_hs")
  ```

  注釈にこの ADR を書く。`.git` の無いフォルダでも、ファイル単位で起動する (`workspace_required` は付けない)。
- フォーマットは、今の conform の `lsp_format = "fallback"` のまま、保存のときに LSP サーバーで行う (設定は足さない)。
- `docs/specifications.md` の nvim の LSP の節と、「自作のツール (mise で入れる)」の表に書く。
- `README.md` は変えない。README には、nvim の LSP や、mise で入れるツールの一覧の節が無いため。

## 実装しないこと

- nvim-lint で `peg-hs lint` を動かすこと (LSP サーバーと二重になる)。
- tree-sitter の文法 (`editors/tree-sitter-hpeg`) によるハイライト。LSP サーバーの semantic tokens で色は付く。tree-sitter は、必要になったら別の ADR で決める。
- 古い `~/.local/bin/peg-hs` を消すこと (dotfiles の外にあり、mise の方が先に引かれる)。消すかは本人が決める。
- バージョンを `0.1.0-rc2` に固定すること (正式なリリースが出たら、そのまま latest で入る)。

## テスト設計

設定の変更なので、CI の自動テストは書かない。実装の前に次を実行して今の値を確かめ、実装の後にもう一度実行して確かめる。

- `command -v peg-hs` が、実装の前は `~/.local/bin/peg-hs`、`mise install` の後は mise の入れたもの (`~/.local/share/mise/installs/github-tett23-peg-hs/0.1.0-rc2/peg-hs`) であること。`peg-hs --help` に `lsp` があること。
- `nvim --headless` で `.hpeg` のファイル (スクラッチパッドに作る) を開き:
  - `vim.bo.filetype` が、実装の前は空、実装の後は `hpeg` であること。
  - `vim.lsp.config.peg_hs` が、実装の前は無く、実装の後はあること。
  - 実装の後、`peg_hs` のクライアントが付くこと (`vim.lsp.get_clients({ name = "peg_hs" })`)。
  - 実装の後、未定義の規則を参照する文法で、diagnostics が 1 つ以上あること (`vim.diagnostic.get(0)`)。
  - 実装の後、インデントを崩した文法を `:w` すると、フォーマットされること (保存の前後で行が変わる)。
- 本人が確かめる: Ghostty の nvim で `.hpeg` を開き、diagnostics・`<Leader>g` の hover・`<Leader>df` の定義のプレビュー・`<Leader>rf` の参照が出る。

## トレードオフ

- peg-hs は pre-release だけなので、`prerelease = true` を付ける。正式なリリースの後も、新しい pre-release が出れば latest で入る。
- 保存のたびに peg-hs のフォーマットが動く。構文の誤りがある文書はフォーマットしない (peg-hs の `docs/adr/0035-language-server.md`)。
- `root_markers` が `.git` なので、ひとつのリポジトリの `.hpeg` は 1 つのサーバーを共有する。

## 参考文献

- peg-hs のリポジトリ (ghq で取得、`d89d8e1`): `README.ja.md` の「Neovim (未確認)」、`docs/specifications.md`、`docs/adr/0035-language-server.md`、`docs/adr/0050-hpeg-extension.md`
- peg-hs の GitHub の Releases (`v0.1.0-rc2` のアセット)
- mise のリポジトリ (ghq で取得、`e6cac97`): `docs/dev-tools/backends/github.md` の `prerelease`
- mise 2026.10.17 での `mise ls-remote`・`mise latest`・`mise exec` の結果
