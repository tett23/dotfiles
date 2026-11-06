# ADR 0092: nvim で Golem の LSP を使う

ステータス: 採択

## 文脈

本人が作っている組版システム Golem（tett23/golem）は、`golem lsp` で LSP のサーバーを起動する。
原稿の `.gm` のファイルで diagnostics と補完が働き、Golem の ADR 0169 からは、プロジェクトのルートの `style.toml` と `preflight.toml` でも補完が働く。
本人から「nvim に LSP を導入」と頼まれた。

- Golem の使い手のマニュアル（第 9 章）は、Neovim の設定の例として次を載せている。

  ```lua
  vim.lsp.config("golem", {
    cmd = { "golem", "lsp" },
    filetypes = { "golem", "toml" },
    root_markers = { "manifest.toml" },
  })
  vim.lsp.enable("golem")
  ```

- 今の nvim の LSP は、mason で入れたサーバーを mason-lspconfig が有効にする（`nvim/lua/plugins/lsp.lua`）。`golem` は mason の外にあり、`~/.local/bin/golem` に置いている（`zsh/exports.sh` で `~/.local/bin` は PATH に入っている）。
- nvim は `.gm` のファイルタイプを知らない。
- `filetypes` に `toml` を入れると、Golem のプロジェクトの外の TOML（`Cargo.toml` など）を開いたときにも、`golem lsp` が起動しうる。nvim 0.11 からの `workspace_required` を真にすると、`root_markers`（`manifest.toml`）が見つからないファイルではサーバーを起動しない。

## 実装すること

- `nvim/lua/config/autocmds.lua` の `vim.filetype.add` の `extension` に、`gm = "golem"` を加える。注釈にこの ADR を書く。
- `nvim/lua/plugins/lsp.lua` の mason-lspconfig の `config` の中で、全サーバー共通の設定（`vim.lsp.config("*", …)`）の後に、次を足す。共通の設定の後に置くので、cmp の capabilities も効く。

  ```lua
  vim.lsp.config("golem", {
    cmd = { "golem", "lsp" },
    filetypes = { "golem", "toml" },
    root_markers = { "manifest.toml" },
    workspace_required = true,
  })
  vim.lsp.enable("golem")
  ```

- `docs/specifications.md` の nvim の LSP の行に、Golem の LSP を mason の外で有効にすることを書く。

## 実装しないこと

- `golem` を mason や Nix で入れること。今は本人が手元で組んだものを `~/.local/bin` に置いている。
- `.gm` の構文の色付け（tree-sitter の文法がない）。
- Golem の LSP の整形を conform に組み込むこと（`golem fmt` を使う設定は、必要になってから決める）。
- ほかのエディタ（VSCode など）の設定。

## テスト設計

nvim の設定の変更なので、CI の自動テストは書かない。実装の前に次を実行して、今の動きを確かめ（失敗を確かめ）、実装の後にもう一度実行して確かめる。

- `nvim --headless` で、`foo.gm` のファイルタイプが `golem` になること。
- `nvim --headless` で、`manifest.toml` のある Golem のプロジェクトの `chapters/01.gm` を開くと、`golem` のクライアントが付き、ルートがプロジェクトのフォルダになること。
- `nvim --headless` で、同じプロジェクトの `style.toml` を開くと、`golem` のクライアントが付くこと。
- `nvim --headless` で、`manifest.toml` のないフォルダの `Cargo.toml` を開いても、`golem` のクライアントが付かないこと。
- 本人が確かめる：Ghostty の nvim で、`.gm` の diagnostics と、`style.toml` の補完が出ること。

## トレードオフ

- `golem` が PATH にないと、`.gm` を開いたときにサーバーの起動に失敗した知らせが出る。nvim を起動する前に `~/.local/bin/golem` を置いておく必要がある。
- `.gm` の拡張子を、ほかのファイルタイプが使っていれば取り合いになる。今の設定に `.gm` を使うものはない。

## 参考文献

- Golem の使い手のマニュアル 第 9 章「エディタ」（tett23/golem の `manual/chapters/09-editor.gm`）
- Golem の ADR 0169: https://github.com/tett23/golem/blob/main/docs/adr/0169-lsp-completion-in-style-and-preflight-toml.md
- Neovim の `:help lsp-config`（`workspace_required`）
