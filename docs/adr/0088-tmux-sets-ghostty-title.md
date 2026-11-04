# ADR 0088: tmux から Ghostty のタイトルに、ディレクトリ名とコマンド名を出す

ステータス: 採択

## 文脈

本人から、tmux でプロセスを動かしている間も、ディレクトリ名を出したいと要望があった。どこに出すかを尋ねると、Ghostty のタイトルとのこと。

- 今は、tmux がタイトルを設定していない (`set-titles` は既定の `off`。`tmux/tmux.conf` に設定は無い)。zsh もタイトルを設定していない。
  Ghostty のシェルインテグレーションのタイトルの機能 (`GHOSTTY_SHELL_FEATURES` の `title`) は、Ghostty が直接起動したシェルだけに入り、
  tmux の中のシェルには入らない ([ADR 0085](0085-open-relative-paths-in-ghostty-through-tmux.md) の文脈)。
- ほかの場所では、プロセスの実行中もディレクトリ名がすでに出ている。ステータスラインのウィンドウの一覧 (`@nova-pane` の `#{b:pane_current_path}`)、
  Ctrl-T のウィンドウの切り替え (`tmux/scripts/window-switcher` の `#{b:pane_current_path}`)。ペインの上の枠 (`pane-border-format`) は
  コマンド名 (`#{pane_current_command}`) だけ。
- tmux(1) によると、`set-titles` が `on` なら、terminfo の `tsl`・`fsl` を使って、手元の端末のタイトルを `set-titles-string` にする
  (書式を展開する)。Ghostty の terminfo (`xterm-ghostty`) には `tsl=\E]2;`・`fsl=^G` がある。
  `set-titles-string` の既定は `#S:#I:#W - "#T" #{session_alerts}` (セッション・ウィンドウの番号・ウィンドウの名前 (コマンド名)・ペインのタイトル)。
- `pane_current_path` と `pane_current_command` は、ペインで前面に動いているプロセスのディレクトリとコマンドで、nvim などを動かしている間も取れる
  (今の tmux で、nvim を動かしているウィンドウの `#{b:pane_current_path}` が `adr-drafts` だった)。
- Ghostty は、タイトルを受け取っていないときだけ、OSC 7 で知らされたディレクトリをタイトルにする (Ghostty の `v1.4.0` の `src/termio/stream_handler.zig`
  の `reportPwd`)。[ADR 0085](0085-open-relative-paths-in-ghostty-through-tmux.md) のトレードオフに、そのためにタイトルが変わるかもしれないと書いた。tmux がタイトルを設定すれば、そうならない。

## 実装すること

- `tmux/tmux.conf` に次を足す。
  - `set -g set-titles on`
  - `set -g set-titles-string "#{b:pane_current_path}: #{pane_current_command}"` (例: `dotfiles: nvim`。今のウィンドウの、選んでいるペインのもの)
- `docs/specifications.md` の tmux の節に書く。

## 実装しないこと

- ペインの上の枠・ステータスライン・ウィンドウの名前 (`automatic-rename-format`) の変更。
- tmux の外 (Ghostty が直接起動したシェル) のタイトル (Ghostty のシェルインテグレーションのまま)。
- フルパスや、セッションの名前をタイトルに出すこと。

## テスト設計

tmux の設定の値の変更のため、自動テストは書かない。次を確かめる。

- 別の tmux サーバー (`tmux -L <名前> -f tmux/tmux.conf`) で、`show -gv set-titles` が `on` になり、
  `display-message -p` で `set-titles-string` の書式を展開すると、`<ディレクトリ名>: zsh` になること。ペインで `sleep 30` を動かしている間は
  `<ディレクトリ名>: sleep` になること。
- `tmux source-file` で今の tmux に読み込み直すとき、エラーが出ないこと。
- 本人が確かめる: Ghostty のタイトル (タブ・ウィンドウ) に、`<ディレクトリ名>: zsh` が出て、nvim を起動すると `<ディレクトリ名>: nvim` に変わること。
  `cd` で移ると、ディレクトリ名が変わること。ウィンドウ・ペインを切り替えると、切り替えた先のものになること。

## トレードオフ

- タイトルの更新は、tmux がステータスラインを描き直すとき (`status-interval` の 2 秒ごとなど) なので、少し遅れることがある。
- Ghostty のタイトルが、tmux を使っている間は常に tmux のものになる。プログラムがペインのタイトルを設定しても (`#T`)、Ghostty のタイトルには出ない。

## 参考文献

- tmux(1) の `set-titles`・`set-titles-string` (tmux 3.8)
- Ghostty の terminfo (`infocmp -x xterm-ghostty` の `tsl`・`fsl`)
- Ghostty の `v1.4.0` のソースの `src/termio/stream_handler.zig` (`reportPwd`): https://github.com/ghostty-org/ghostty
