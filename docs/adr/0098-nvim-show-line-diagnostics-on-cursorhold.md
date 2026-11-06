# ADR 0098: nvim でカーソルを止めると、その行の診断を lspsaga で出す

ステータス: 採択

## 文脈

[ADR 0097](0097-nvim-lspsaga-instead-of-adr-0096.md) で、LSP の表示を lspsaga.nvim にした。
本人から「ホバーで表示できるものはあるか」と聞かれ、マウスの位置で出す方法 (hover.nvim) と、カーソルを止めたときに出す方法を挙げた。本人は「カーソルで、診断だけ」を選んだ。

調べたことは次のとおり。

- nvim は、カーソルを `updatetime` ミリ秒動かさないと `CursorHold` のイベントを起こす。今の `updatetime` は既定の 4000 (`nvim --clean` で確かめた)。
  `updatetime` はスワップファイルを書く間隔も兼ねるが、スワップファイルは使っていない (`opt.swapfile = false`)。
- lspsaga.nvim (ghq で取得したリポジトリ、`cf6fc94`) の `lua/lspsaga/diagnostic/show.lua`:
  - `:Lspsaga show_line_diagnostics` はカーソルのある行の診断を、`show_cursor_diagnostics` はカーソルの位置の診断を、浮動ウィンドウに出す。
  - 診断が無いときは、何も出さずに戻る (`if next(entrys) == nil then return end`)。
  - 引数に `++unfocus` を付けないと、浮動ウィンドウにカーソルが移る。付けると移らず、`CursorMoved`・`CursorMovedI`・`InsertEnter`・`BufDelete`・`BufLeave` で閉じる。
  - 診断へ移る浮動ウィンドウ (`[d`・`]d`) が開いているときは、何も出さない。
- lspsaga.nvim は `event = "LspAttach"` で読み込んでいる。`:Lspsaga` は読み込むまで無いので、LSP の付いていないバッファ (nvim-lint の診断だけがあるバッファなど) では、このままでは使えない。
  lazy.nvim の `cmd` に書くと、コマンドを使ったときにも読み込む。

## 実装すること

- `nvim/lua/config/options.lua` で `opt.updatetime = 1000` にする。注釈に、この ADR と、スワップファイルを使っていないので書き込みは増えないことを書く。
- `nvim/lua/config/autocmds.lua` に、`CursorHold` で `Lspsaga show_line_diagnostics ++unfocus` を実行する autocmd を足す。
  - カーソルのある行の診断を出す (位置ではなく行。行のどこにカーソルがあっても出る)。
  - `++unfocus` を付け、カーソルを浮動ウィンドウに移さない。カーソルを動かすと閉じる。
  - ノーマルモードだけ (`CursorHoldI` は使わない)。
  - 通常のファイルのバッファ (`buftype` が空) だけで実行する。
  - 注釈にこの ADR を書く。
- `nvim/lua/plugins/lsp.lua` の lspsaga.nvim に `cmd = "Lspsaga"` を足し、LSP の付いていないバッファでも `:Lspsaga` で読み込めるようにする。
- `docs/specifications.md` の lspsaga の項目に書く。

## 実装しないこと

- hover (`Lspsaga hover_doc`) を自動で出すこと。
- マウスの位置で出すこと (hover.nvim、`mousemoveevent`)。
- 挿入モードで出すこと。
- 行の右に出す診断 (`virtual_text`) をやめること。

## テスト設計

nvim の設定の変更なので、CI の自動テストは書かない。実装の前に次を実行して今の値を確かめ、実装の後にもう一度実行して確かめる。

- `nvim --headless` で、`vim.o.updatetime` が、実装の前は 4000、実装の後は 1000 であること。
- `nvim --headless` で、`CursorHold` の autocmd に、この ADR のものが、実装の前は無く、実装の後はあること (`nvim_get_autocmds({ event = "CursorHold" })`)。
- `nvim --headless` で、診断を 1 つ置いたバッファ (`vim.diagnostic.set` で作る。LSP は付けない) の、その行にカーソルを置いて `CursorHold` を起こすと:
  - 浮動ウィンドウが 1 つ開き、中に診断のメッセージがあること。
  - カーソルは元のウィンドウにあること。
  - カーソルを別の行に動かすと、浮動ウィンドウが閉じること。
- 診断の無い行で `CursorHold` を起こしても、浮動ウィンドウが開かないこと。
- 本人が確かめる: Ghostty の nvim で、診断のある行でカーソルを 1 秒止めると、診断が浮動ウィンドウで出て、カーソルを動かすと消える。

## トレードオフ

- 診断のある行でカーソルを止めるたびに、浮動ウィンドウが出る。行の右の診断と、内容が重なる。
- `updatetime` を縮めると、`CursorHold` を使うほかのもの (入れているプラグインでは trouble.nvim の LSP の一覧の更新) も早く動く。
- `show_line_diagnostics` の `++unfocus` と、`CursorHold` の autocmd の組み合わせは、lspsaga の内部の動き (閉じるイベント) に頼る。lspsaga の更新で変わることがある。

## 参考文献

- lspsaga.nvim のリポジトリ (ghq で取得、`cf6fc94`): `lua/lspsaga/command.lua`、`lua/lspsaga/diagnostic/show.lua`
- Neovim 0.12.6 の `nvim --clean` での `updatetime` の値
- 入れているプラグインの `CursorHold` を使う箇所 (`rg CursorHold ~/.local/share/nvim/lazy`): trouble.nvim の `lua/trouble/sources/lsp.lua`
