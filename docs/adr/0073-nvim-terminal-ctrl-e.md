# ADR 0073: nvim のターミナルがノーマルモードでも、Ctrl-E をシェルに渡す

ステータス: 採択

## 文脈

zsh の `Ctrl-E` は、fzf で git の worktree を選んで移動する ([ADR 0070](0070-fzf-worktree-switcher.md))。本人から、nvim の toggleterm の中で
`Ctrl-E` を押すと、入力が nvim に吸われるようだと報告があった。

別の tmux サーバーで nvim を起動し、toggleterm (`Ctrl-\` で開く浮いたウィンドウ) の中で確かめた。

- ターミナルの入力モード (`-- TERMINAL --`) では、`Ctrl-E` はシェルに届き、worktree の一覧が出て、選ぶと移動できた。
- ターミナルのバッファがノーマルモードのとき (`mode()` が `n`。nvim の外から `stopinsert` して作った) に `Ctrl-E` を押すと、
  winresizer (`nvim/lua/plugins/windows.lua`) のノーマルモードの割り当て (`<C-e>` → `:WinResizerStartResize`) が働き、
  `[window resize mode]` になった。シェルには届かない。
- ターミナルのバッファがノーマルモードになるのは、マウスのホイールでスクロールしたとき (`mouse=a`) などで、本人が意識せずに入りやすい。
  toggleterm は前のモードを覚える (`persist_mode` が既定で `true`) ので、ノーマルモードのまま閉じると、開き直してもノーマルモードになる。
  `Ctrl-\ Ctrl-N` は、toggleterm がターミナルの入力モードでも `Ctrl-\` を開閉に割り当てているため、ノーマルモードに入る前に閉じる。
- 回避策として、ターミナルのバッファだけに、ノーマルモードの `<C-e>` を「入力モードに入ってから `Ctrl-E` を送る」(`i<C-e>`) 割り当てを
  バッファごとに付けたところ、ノーマルモードから `Ctrl-E` で worktree の一覧が出た (同じ手順で確かめた)。
  バッファごとの割り当ては、winresizer の全体の割り当てより優先される。

## 実装すること

- `nvim/lua/config/autocmds.lua` に、`TermOpen` (ターミナルのバッファを作ったとき) で、そのバッファのノーマルモードの `<C-e>` を
  `i<C-e>` (`noremap`) にする autocmd を足す。toggleterm も `:terminal` も対象になる。
- `docs/specifications.md` の nvim の節に書く。

## 実装しないこと

- winresizer の起動キー (`<C-e>`) を変えること (ふつうのバッファでの使い方は変えない)。
- toggleterm の `persist_mode` を `false` にすること (開き直すと入力モードに戻るが、スクロールした後に同じウィンドウで押す場合は直らない)。
- `Ctrl-E` 以外の zsh の fzf のキー (`Ctrl-P`・`Ctrl-G` など) を同じように扱うこと (今回は報告のあった `Ctrl-E` だけ)。

## テスト設計

- nvim の設定の変更のため、自動テストは書かない。次を確かめる。
  - nvim をヘッドレスで起動し、`:terminal` と `:ToggleTerm` で作ったバッファで、ノーマルモードの `<C-e>` がバッファごとの `i<C-e>` であること
    (`maparg` の `buffer` と `rhs`)。ふつうのバッファでは、今どおり winresizer の割り当てであること。
  - 別の tmux サーバーで nvim を起動し、toggleterm を開いてノーマルモードにし (`--listen` のソケットから `stopinsert`)、`Ctrl-E` で
    worktree の一覧が出ること。入力モードのままでも、今どおり一覧が出ること。
- 実際の使い方 (スクロールした後に `Ctrl-E`) は本人が確かめる。

## トレードオフ

- ターミナルのバッファのノーマルモードで `<C-e>` を押すと、入力モードに戻る (スクロールしていた位置から、最下部に戻る)。
- ターミナルのバッファでは、ノーマルモードの `<C-e>` で winresizer を起動できなくなる (ふつうのバッファに移れば使える)。
- nvim の本来の `<C-e>` (1 行スクロール) は、もともと winresizer が上書きしていて使えない。

## 参考文献

- Neovim の terminal (Terminal モードとノーマルモード、`TermOpen`): https://neovim.io/doc/user/terminal.html
- toggleterm.nvim (`open_mapping`・`persist_mode`): https://github.com/akinsho/toggleterm.nvim
- winresizer: https://github.com/simeji/winresizer
