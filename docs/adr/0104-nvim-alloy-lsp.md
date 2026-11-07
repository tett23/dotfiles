# ADR 0104: nvim で Alloy の LSP サーバー (alloy6 lsp) を使う

ステータス: 採択

## 文脈

[ADR 0103](0103-java-and-alloy.md) で Alloy を入れた (nixpkgs の `alloy6`)。本人から、nvim で Alloy の LSP を使えるようにするよう頼まれた。

調べたことは次のとおり。

- `alloy6` は PATH から引ける (`/etc/profiles/per-user/tett23/bin/alloy6`)。サブコマンド `lsp` があり、`alloy6 help lsp` の書式は `lsp <[port]>`。
- `alloy6 lsp` をポートなしで起動し、標準入出力で LSP の要求を送った (スクラッチパッドの Python のスクリプト):
  - `initialize` に、`hoverProvider`・`definitionProvider`・`referencesProvider`・`documentSymbolProvider`・`workspaceSymbolProvider`・
    `codeLensProvider`・`renameProvider`・`documentLinkProvider` を返す。`textDocumentSync` は 1 (全文)。フォーマットは無い。
  - `sig A {}` と `run { some B } for 3` のファイルで、`didOpen` から 5 秒では diagnostics が来なかった。`didSave` を送ると、
    `The name "B" cannot be found.` の diagnostics (2 行目の `B`) が来た。保存したときに検査するとみられる。
  - このファイルでは、`documentSymbol` と `hover` (`A` の上) は `null` を返した。
- nvim 0.12.6 は `.als` のファイルタイプを持たない (`vim.filetype.match({ filename = "m.als" })` は何も返さない)。
- nvim-lspconfig (`292f4440`) に `alloy_ls` がある。`cmd = { "alloy", "lsp" }`、`filetypes = { "alloy" }`、`root_markers = { ".git" }`。
  ファイルタイプ `alloy` は自分で足すよう書いてある。nixpkgs のコマンドの名前は `alloy6` なので、`cmd` は合わない。
- `alloy_ls` は mason で入れていないので、mason-lspconfig の `automatic_enable` では有効にならない。
- nvim-treesitter に Alloy のパーサーは無い。

## 実装すること

- `nvim/lua/config/autocmds.lua` の `vim.filetype.add` の `extension` に `als = "alloy"` を足す。
- `nvim/lua/plugins/lsp.lua` で、nvim-lspconfig の `alloy_ls` の `cmd` を `{ "alloy6", "lsp" }` に変えて有効にする
  (`vim.lsp.config("alloy_ls", { cmd = { "alloy6", "lsp" } })` と `vim.lsp.enable("alloy_ls")`)。ほかは nvim-lspconfig の既定のまま。
- `docs/specifications.md` の nvim の LSP の節に書く。README は nvim の LSP の一覧を持たないので変えない。

## 実装しないこと

- シンタックスハイライト (tree-sitter のパーサー、vim-alloy などのプラグイン)。
- code lens (Alloy の LSP がモデルを実行するコマンドを出すとみられるもの) を nvim で出すこと。
- フォーマット (Alloy の LSP サーバーが持たない)。

## テスト設計

設定の変更なので、CI の自動テストは書かない。実装の前に次を実行して今の値を確かめ (上の「文脈」)、実装の後にもう一度実行して確かめる (nvim を `--headless` で起動し、スクラッチパッドの `.als` を開く)。

- `.als` のファイルタイプが `alloy` になる (実装の前は空)。
- `vim.lsp.get_clients({ bufnr = 0 })` に `alloy_ls` が付き、`cmd` が `{ "alloy6", "lsp" }` である (実装の前は付かない)。
- 名前の誤り (`run { some B }`) のあるファイルを開いて `:w` すると、`vim.diagnostic.get(0)` に `The name "B" cannot be found.` が入る。
- 本人が確かめる: Ghostty の nvim で `.als` を開いて保存すると、誤りの行に diagnostics が出る。

## 結果

nvim を `--headless` で起動し、スクラッチパッドの `.als` (`sig A {}` と `run { some B } for 3`) を開いて、`:w` の後に diagnostics を待った。

| 項目 | 実装の前 | 実装の後 |
| --- | --- | --- |
| ファイルタイプ | 空 | `alloy` |
| 付いた LSP クライアント | 無し | `alloy_ls` (`alloy6 lsp`) |
| 保存の後の diagnostics | 無し | 2 行目 `The name "B" cannot be found.` |

## トレードオフ

- diagnostics は保存したときに出る。打っている途中には出ない。
- ハイライトが無いので、`.als` は色が付かない。

## 参考文献

- nvim-lspconfig (`292f4440`) の `lsp/alloy_ls.lua`
- `alloy6 help lsp` と、標準入出力で `alloy6 lsp` に送った要求の結果
- Alloy のリポジトリ: https://github.com/AlloyTools/org.alloytools.alloy
