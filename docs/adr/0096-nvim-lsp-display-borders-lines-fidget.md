# ADR 0096: nvim の LSP の表示を見やすくする (浮動ウィンドウの枠、診断の行、fidget.nvim)

ステータス: 採択→[ADR 0097](0097-nvim-lspsaga-instead-of-adr-0096.md)

## 文脈

本人から「LSP をいい感じに表示する nvim のプラグインはあるか」と聞かれ、候補を挙げた。そのうち、nvim に組み込みの 2 つと fidget.nvim を選んだ。

今の nvim (0.12.6) の LSP の表示は次のとおり。

- hover や補完の説明などの浮動ウィンドウには、枠が無い (`winborder` は既定の空)。
- 診断は、行の右にメッセージを出す (`vim.diagnostic.config({ virtual_text = true, severity_sort = true })`。[ADR 0055](0055-improvements-2026-10-13.md))。
  長いメッセージは画面の右で切れ、読めない。
- サーバーの起動や解析の進み具合 (`$/progress`) は、どこにも出ない。

調べたことは次のとおり。

- `:help 'winborder'` (nvim 0.12.6): 浮動ウィンドウの既定の枠を決めるグローバルなオプション。値は `bold`・`double`・`none`・`rounded`・`shadow`・`single`・`solid` など。既定の空は `none` と同じ。
- `:help vim.diagnostic.Opts.VirtualLines`: 診断を、行の下に別の行として出す。`current_line = true` で、カーソルのある行の診断だけを出す。
- fidget.nvim の README: LSP の `$/progress` を、画面の隅に小さく出す。Neovim 0.11.3 以上が要る。lazy.nvim では `{ "j-hui/fidget.nvim", opts = {} }` で入れる。`main` には互換の無い変更が入ることがあるので、`version = "*"` でリリースのタグに固定できる。
  `notification.override_vim_notify` は既定で `false` (`vim.notify` は置き換えない)。
- GitHub の API で見た fidget.nvim (2026-11-05): スター 2602、最後の push は 2026-09-03、アーカイブされていない。

## 実装すること

- `nvim/lua/config/options.lua`:
  - `opt.winborder = "rounded"` を足す。hover・シグネチャ・診断の浮動ウィンドウなどに、角の丸い枠が付く。
  - `vim.diagnostic.config` に `virtual_lines = { current_line = true }` を足す。カーソルのある行の診断を、行の下に全文で出す。
    ほかの行の診断は、今までどおり行の右に出す (`virtual_text = true` はそのまま)。
- `nvim/lua/plugins/lsp.lua` に fidget.nvim を足す。

  ```lua
  { "j-hui/fidget.nvim", version = "*", event = "LspAttach", opts = {} }
  ```

  注釈にこの ADR を書く。`opts` は既定のままにする (`vim.notify` は置き換えない)。
- `nvim/lazy-lock.json` を更新する。
- `docs/specifications.md` の nvim の LSP の項目に書く。

## 実装しないこと

- 行の右に出す診断 (`virtual_text`) をやめること。カーソルのある行では、右のメッセージと下の行の両方に同じ診断が出る (トレードオフに書く)。
- fidget.nvim で `vim.notify` を置き換えること (`override_vim_notify`)。
- そのほかの候補 (tiny-inline-diagnostic.nvim、glance.nvim、outline.nvim、aerial.nvim、lspsaga.nvim、noice.nvim)。

## テスト設計

nvim の設定の変更なので、CI の自動テストは書かない。実装の前に次を実行して今の値を確かめ、実装の後にもう一度実行して確かめる。

- `nvim --headless` で、`vim.o.winborder` が、実装の前は空、実装の後は `rounded` であること。
- `nvim --headless` で、`vim.diagnostic.config().virtual_lines` が、実装の前は偽、実装の後は `{ current_line = true }` であること。`virtual_text` は実装の前後とも真であること。
- `nvim --headless` で、`.lua` のファイルを開いて LSP のクライアント (lua_ls) が付いた後、fidget.nvim が読み込まれていること (`require("lazy.core.config").plugins["fidget.nvim"]._.loaded`)。
- 本人が確かめる: Ghostty の nvim で、
  - `K` の hover に丸い枠が付く。
  - 診断のある行にカーソルを置くと、行の下に診断の全文が出る。
  - ファイルを開いたとき、画面の右下に LSP の進み具合が出て、終わると消える。

## トレードオフ

- カーソルのある行では、診断が右と下の 2 か所に出る。
- 診断の行は、カーソルを動かすたびに出たり消えたりするので、下の本文が上下に動く。
- `winborder` はグローバルなので、LSP 以外の浮動ウィンドウ (プラグインが枠を指定していないもの) にも枠が付く。
- fidget.nvim はプラグインが 1 つ増える。進み具合 (`$/progress`) を送らないサーバーでは何も出ない。

## 参考文献

- Neovim 0.12.6 の `:help 'winborder'`、`:help vim.diagnostic.Opts.VirtualLines`
- fidget.nvim の README: https://github.com/j-hui/fidget.nvim
