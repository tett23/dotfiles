# ADR 0090: nvim の `;` と `:` を、また入れ替える

ステータス: 採択

## 文脈

[ADR 0089](0089-nvim-restore-semicolon-and-colon.md) で、nvim の `;` と `:` の入れ替えをやめ、既定の動きに戻した。その後、本人から「ノーマルモードから
`:` でコマンドラインに入れない」と知らせがあった。

- Ghostty の nvim にキーの記録を仕込み、本人に、いつもどおりコマンドラインに入る押し方をしてもらうと、nvim に届いたのは `;` (Shift 無し) だった。
  `:` の割り当ては無く (`verbose nmap :` が `No mapping found`)、tmux・Ghostty・Karabiner にも `:`・`;` を変える設定は無かった。
- 本人に尋ねると、コマンドラインには、Shift を押さずに `;` のキーで入りたいとのこと。これは、[ADR 0089](0089-nvim-restore-semicolon-and-colon.md) でやめた入れ替えの動き
  (旧 `vim/keymap.vim` の `noremap ; :`・`noremap : ;` から移したもの) と同じ。
- [ADR 0089](0089-nvim-restore-semicolon-and-colon.md) の「`;` と `:` を入れ替えをやめる」は、本人の求めと違っていた (本人は、入れ替わっていることを、入れ替えていないものと思っていた)。

## 実装すること

- `nvim/lua/config/keymaps.lua` に、[ADR 0089](0089-nvim-restore-semicolon-and-colon.md) で消した 2 行を戻す (`map("", ";", ":")`・`map("", ":", ";")`。ノーマル・ビジュアル・オペレータ待ちのモード)。
  注釈に、この ADR を書く。
- [ADR 0089](0089-nvim-restore-semicolon-and-colon.md) のステータスを「採択→ADR 0090」にする。
- `docs/specifications.md` の nvim の節の、[ADR 0089](0089-nvim-restore-semicolon-and-colon.md) の行を、「`;` でコマンドラインに入り、`:` で `f`・`t` を繰り返す (入れ替える)」に直す。

## 実装しないこと

- `,` の割り当ての変更 (既定のとおり、`f`・`t` を逆向きに繰り返す)。
- flash.nvim の設定の変更 (`;` に割り当てがあるので、flash は `;` を使わない。[ADR 0089](0089-nvim-restore-semicolon-and-colon.md) より前と同じ)。
- ほかのエディタ (VSCode など) の設定の変更。

## テスト設計

nvim のキーの割り当ての変更のため、CI の自動テストは書かない。実装の前に次を実行して、今の動きを確かめ (失敗を確かめ)、実装の後にもう一度実行して確かめる。

- `nvim --headless` で、ノーマルモードの `;` が `:` に、`:` が `;` に割り当てられていること (`maparg`)。
- `nvim --headless` で、`;` を押すとコマンドラインに入ること (`mode=c`)。
- `nvim --headless` で、行 `xaxaxa` の先頭から `fa:` と押すと、0 から数えて 3 文字目に移ること。
- 本人が確かめる: Ghostty の nvim で、Shift 無しの `;` のキーでコマンドラインに入ること。

## トレードオフ

- [ADR 0089](0089-nvim-restore-semicolon-and-colon.md) より前と同じく、`f`・`t` を同じ向きに繰り返すには `:` (Shift+`;`) を押す。

## 参考文献

- nvim の `:help ;`・`:help :`
- [ADR 0089](0089-nvim-restore-semicolon-and-colon.md) (入れ替えをやめたときの調査)
