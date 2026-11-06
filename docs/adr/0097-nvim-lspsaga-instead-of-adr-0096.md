# ADR 0097: nvim の LSP の表示を lspsaga.nvim にする (0096 を置き換える)

ステータス: 採択

## 文脈

[ADR 0096](0096-nvim-lsp-display-borders-lines-fidget.md) で、浮動ウィンドウの枠 (`winborder = "rounded"`)、カーソルのある行の診断を行の下に出す表示 (`virtual_lines`)、fidget.nvim を入れた。
本人が使ってみて「見た目が微妙なので lspsaga.nvim に置き換えて」と頼まれた。

lspsaga.nvim (nvimdev/lspsaga.nvim) について調べたことは次のとおり。

- ghq で取得したリポジトリ (最新のコミット `cf6fc94`、2026-07-16):
  - `plugin/lspsaga.lua` が `:Lspsaga` コマンドを作る。サブコマンドは `lua/lspsaga/command.lua` にあり、`hover_doc`・`peek_definition`・`goto_definition`・`finder`・`rename`・`code_action`・`diagnostic_jump_next`・`diagnostic_jump_prev`・`show_line_diagnostics`・`outline` など。
  - `lua/lspsaga/init.lua` の既定値:
    - `ui.border = 'rounded'` (lspsaga の浮動ウィンドウは自分で枠を付ける)。`ui.use_nerd = true` (Nerd Font の記号を使う)。
    - `symbol_in_winbar.enable = true` (winbar に、今いる関数などの位置を出す)。
    - `lightbulb.enable = true` (コードアクションがある行に 💡 を出す)。
  - nvim-web-devicons は無くても動く (`pcall(require, 'nvim-web-devicons')`)。
- ドキュメントのサイト (https://nvimdev.github.io/lspsaga/) の lazy.nvim の例は、`require('lspsaga').setup({})` を呼び、`dependencies` に nvim-treesitter と nvim-web-devicons (どちらも optional) を書く。遅延読み込みは `event = 'LspAttach'` でできる。
- GitHub の API で見た lspsaga.nvim (2026-11-05): スター 3800、最後の push は 2026-07-16、アーカイブされていない。

今の LSP のキーは `nvim/lua/config/keymaps.lua` にある: `<Leader>g` (hover)、`<Leader>df` (定義)、`<Leader>rf` (参照)、`<Leader>rn` (名前の変更)。

## 実装すること

- [ADR 0096](0096-nvim-lsp-display-borders-lines-fidget.md) で入れたものを外す。
  - `nvim/lua/config/options.lua` の `winborder = "rounded"` と、`vim.diagnostic.config` の `virtual_lines`。行の右に出す診断 (`virtual_text`) と `severity_sort` は残す ([ADR 0055](0055-improvements-2026-10-13.md))。
  - `nvim/lua/plugins/lsp.lua` の fidget.nvim。
- `nvim/lua/plugins/lsp.lua` に lspsaga.nvim を足す。

  ```lua
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {},
  }
  ```

  設定は既定のまま (winbar の位置の表示と 💡 も出す)。注釈にこの ADR を書く。
- `nvim/lua/config/keymaps.lua` の LSP のキーを、lspsaga のコマンドに変える。キーは今のまま。
  - `<Leader>g`: `<cmd>Lspsaga hover_doc<cr>`
  - `<Leader>df`: `<cmd>Lspsaga peek_definition<cr>` (定義を、移動せずに浮動ウィンドウで見る。そこから `<C-o>` で開ける)
  - `<Leader>rf`: `<cmd>Lspsaga finder<cr>` (参照と実装の一覧)
  - `<Leader>rn`: `<cmd>Lspsaga rename<cr>`
- 次のキーを足す。今は割り当てが無い。
  - `<Leader>ca`: `<cmd>Lspsaga code_action<cr>`
  - `[d`・`]d`: `<cmd>Lspsaga diagnostic_jump_prev<cr>`・`<cmd>Lspsaga diagnostic_jump_next<cr>` (nvim の既定の `[d`・`]d` を置き換え、移った先の診断を浮動ウィンドウで出す)
- `nvim/lazy-lock.json` を更新する (fidget.nvim を消し、lspsaga.nvim を足す)。
- `docs/specifications.md` の [ADR 0096](0096-nvim-lsp-display-borders-lines-fidget.md) の項目を、この ADR の内容に書き換える。キーの表があれば直す。
- [ADR 0096](0096-nvim-lsp-display-borders-lines-fidget.md) のステータスを「採択→ADR 0097」にする。

## 実装しないこと

- lspsaga の既定値の変更 (見た目を確かめてから、必要なら別の ADR で決める)。
- `K` (nvim の既定の hover) の置き換え。
- `:Lspsaga outline`・`incoming_calls` などのキーの割り当て (コマンドでは使える)。
- trouble.nvim を外すこと (診断の一覧は trouble のまま)。

## テスト設計

nvim の設定の変更なので、CI の自動テストは書かない。実装の前に次を実行して今の値を確かめ、実装の後にもう一度実行して確かめる。

- `nvim --headless` で `.lua` のファイルを開き、LSP のクライアント (lua_ls) が付いた後に:
  - `vim.o.winborder` が、実装の前は `rounded`、実装の後は空であること。
  - `vim.diagnostic.config().virtual_lines` が、実装の前は `{ current_line = true }`、実装の後は偽であること。`virtual_text` は真のままであること。
  - fidget.nvim が、実装の前は読み込まれていて、実装の後は lazy.nvim の一覧に無いこと。
  - lspsaga.nvim が、実装の後は読み込まれていて、`:Lspsaga` コマンドがあること。
  - `maparg` で、`<Leader>g`・`<Leader>df`・`<Leader>rf`・`<Leader>rn`・`<Leader>ca`・`[d`・`]d` が、実装の後は上の `Lspsaga` のコマンドであること。
- 本人が確かめる: Ghostty の nvim で、
  - `<Leader>g` の hover、`<Leader>df` の定義のプレビュー、`<Leader>rf` の一覧が、枠付きの浮動ウィンドウで出る。
  - 画面の上 (winbar) に、今いる関数などの位置が出る。
  - コードアクションがある行に 💡 が出る。
  - アイコン (Nerd Font の記号) が、豆腐 (□) にならずに表示される。

## トレードオフ

- lspsaga.nvim は機能が多く、fidget.nvim より大きい。使わない機能 (`floaterm` など) も入る。
- LSP の進み具合 (fidget.nvim) は出なくなる。
- winbar に位置の表示が出るので、本文の表示が 1 行減る。
- アイコンは Nerd Font の記号を使う (`ui.use_nerd = true`)。今の Ghostty のフォントで表示できるかは確かめていない。豆腐になる場合は、別の ADR で `use_nerd` などを決める。
- `[d`・`]d` は nvim の既定の動き (診断に移るだけ) から、lspsaga の動き (移って浮動ウィンドウを出す) に変わる。

## 参考文献

- lspsaga.nvim のリポジトリ (ghq で取得、`cf6fc94`): `plugin/lspsaga.lua`、`lua/lspsaga/command.lua`、`lua/lspsaga/init.lua`、`lua/lspsaga/util.lua`
- lspsaga.nvim のドキュメントのサイト: https://nvimdev.github.io/lspsaga/
