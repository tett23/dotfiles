# ADR 0052: tmux のウィンドウの切り替えを tmux の Ctrl-T (ポップアップ) にし、nvim の中でも使えるようにする

ステータス: 採択

## 文脈

fzf で tmux のウィンドウを選んで切り替える機能 ([ADR 0033](0033-fzf-tmux-window-switcher.md)) は、zsh のウィジェット `ftmux_window` で、`Ctrl-T` に割り当てている
([ADR 0036](0036-tmux-window-switcher-on-ctrl-t.md))。zsh の入力行でしか効かず、nvim など zsh 以外のプログラムを動かしているときは使えない。
nvim の中でも `Ctrl-T` で使いたい。nvim の既定の `Ctrl-T` (タグの移動の後戻り) は使えなくなってよい。

- tmux の prefix 無しの割り当て (`bind -n`) にすると、tmux がペインのプログラムより先にキーを受け取るので、zsh・nvim のどちらでも効く。
- tmux 3.2 以降は、ポップアップ (`display-popup`) の中でコマンドを動かせる (手元は 3.7c)。
- 今の切り替えの処理は zsh の関数 `__ftmux_window` (`zsh/fzf.sh`) にあり、zsh の fzf の補助関数 (`_fzf_run`) を使っている。
  ポップアップから使うには、zsh の設定に頼らないスクリプトにする必要がある。
- ポップアップのコマンドの文字列は、tmux が書式 (`#{...}`) を展開してから実行する。

## 実装すること

- 切り替えの処理を、スクリプト `tmux/scripts/window-switcher` (POSIX sh) に移す。
  - 引数に今いるウィンドウ (`<セッション>:<ウィンドウ番号>`) を受け取り、一覧で `*` を付ける。
  - 一覧の形式・プレビュー (`tmux capture-pane -ep`)・切り替え方 (`select-window` と `switch-client`) は [ADR 0033](0033-fzf-tmux-window-switcher.md) のまま。
  - fzf は画面いっぱいで、一覧を上から並べる (`--reverse`)。
- `tmux/tmux.conf` に、prefix 無しの `Ctrl-T` で、ポップアップの中でこのスクリプトを動かす割り当てを足す。

  ```tmux
  bind -n C-t display-popup -E -w 80% -h 70% "$DOTFILES/tmux/scripts/window-switcher '#{session_name}:#{window_index}'"
  ```

- `zsh/fzf.sh` の `__ftmux_window` も、このスクリプトを呼ぶだけにする (コマンド選択 `Ctrl-O` から使えるように残す)。
  zsh の `bindkey "^t" ftmux_window` は残す (tmux の中では tmux が先に受け取るので、実際には tmux の割り当てが動く)。
- CI の shellcheck の対象にスクリプトを足す。`docs/specifications.md` の tmux と zsh の節を直す。
- [ADR 0036](0036-tmux-window-switcher-on-ctrl-t.md) のステータスを「採択→Ctrl-T の受け取り先 (zsh から tmux へ) は[ADR 0052](0052-tmux-window-switcher-in-tmux.md)」にする。

## 実装しないこと

- tmux の外 (Ghostty で tmux を使っていないとき) での切り替え (tmux の外ではウィンドウが無い)。
- nvim の `Ctrl-T` の代わりの割り当て (タグの移動の後戻りは `:pop` で使える)。

## テスト設計

- 切り替えはシェルスクリプトで tmux と fzf の操作が中心のため、自動テストは書かない。shellcheck が通ること。
- 別の tmux サーバーに複数のセッション・ウィンドウを作り、fzf の代わりに決まった行を選ぶ偽のコマンドで、次を確かめる。
  - スクリプトが一覧を [ADR 0033](0033-fzf-tmux-window-switcher.md) の形式で出し、引数のウィンドウに `*` を付けること。
  - 選んだウィンドウに切り替わること。
- 設定を読み込んだ tmux で、`list-keys -T root` の `C-t` が上の割り当てになっていること。
- `zsh/tests/` のテストがすべて通ること (コマンド選択の一覧の `ftmux_window` のキーは `^T` のまま)。
- 実際に zsh と nvim の中で `Ctrl-T` を押してポップアップが出て、選んだウィンドウに切り替わることは本人が確かめる。

## トレードオフ

- tmux の中では、どのプログラムでも `Ctrl-T` が tmux に取られる (nvim のタグの移動の後戻り、ほかのプログラムの `Ctrl-T` も使えない)。
- 一覧がポップアップになり、zsh の入力行の下に出ていた形 ([ADR 0033](0033-fzf-tmux-window-switcher.md)) から見た目が変わる。
