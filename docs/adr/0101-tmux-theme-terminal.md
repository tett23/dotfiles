# ADR 0101: tmux 3.8 の色のテーマを、端末の色 (terminal) にする

ステータス: 採択

## 文脈

本人から、fzf で `Ctrl-T` を押したときに、背景が灰色になるのを直したいと頼まれた。
`Ctrl-T` は tmux の `display-popup` で `tmux/scripts/window-switcher` (fzf でウィンドウを選ぶ) を開く ([ADR 0036](0036-tmux-window-switcher-on-ctrl-t.md)、[ADR 0052](0052-tmux-window-switcher-in-tmux.md))。
本人のスクリーンショットでは、ポップアップの中の全体が中くらいの灰色になっている。

調べたことは次のとおり。

- 手元の tmux は 3.8 (Nix で入れた `/nix/store/…-tmux-3.8`)。
- tmux の `CHANGES` の「CHANGES FROM 3.7c TO 3.8」: 明るいテーマと暗いテーマの色が組み込まれ、新しい `theme` のオプションで、端末のテーマを検出するか、端末の色を使うか、明るいか暗いかに固定するかを決める。
  元の色にするには `terminal` にする、とある (「set to terminal for the old colours」)。
- tmux のソース (ghq で取得、`a73616d`) の `options-table.c`:
  - `popup-style` の既定は `bg=themedarkgrey,fg=themewhite`、`popup-border-style` の既定は `bg=themedarkgrey,fg=themelightgrey`。メニュー、モードなど、ほかの組み込みの色も `theme…` の色を使う。
  - `dark-theme-dark-grey` は `gray15`、`light-theme-dark-grey` は `gray45` (どちらも 256 色以上の端末のとき)。
- 今の値 (今の tmux のサーバーで確かめた):
  - `theme` は `detect`。`#{client_theme}` は `light`。`popup-style` は `bg=themedarkgrey,fg=themewhite`。
  - つまり、ポップアップの背景は `gray45` で、スクリーンショットの灰色と合う。
- tmux のソースの `server-client.c` と `colour.c`: `detect` では、端末が知らせたテーマを使い、知らせなければ背景の色の明るさで決める。
  `terminal` では、テーマの色を端末の ANSI の色に置き換える (`colour_theme_table`。たとえば `themedarkgrey` は 0 番、`themewhite` は 7 番)。
- macOS の外観はライトモード (`defaults read -g AppleInterfaceStyle` に値が無い)。Ghostty の色は暗い `Monokai Classic` (`ghostty/config` の `theme`)。
  Ghostty が tmux に明るいテーマを知らせている理由 (macOS の外観を知らせているのか) は、確かめていない。
- dotfiles の `tmux/tmux.conf` は、`popup-style`・`popup-border-style`・`theme` を設定していない。

## 実装すること

- `tmux/tmux.conf` に `set -g theme terminal` を足す。tmux の組み込みの色 (ポップアップ、メニュー、モードなど) を、3.7 までと同じく端末の色にする。
  注釈に、tmux 3.8 で組み込みのテーマができたこと、端末が明るいテーマと知らせるとポップアップが灰色 (`gray45`) になることと、この ADR を書く。
- `docs/specifications.md` の tmux の節に書く。

## 実装しないこと

- `theme dark` で暗いテーマに固定すること。ポップアップの背景が `gray15` の灰色になり、端末の背景と違う色になる。
- `popup-style` だけを `default` にすること。ポップアップは直るが、メニューやモードは明るいテーマの色のまま残る。
- Ghostty が知らせるテーマを変えること (macOS の外観、Ghostty の設定)。

## テスト設計

設定の変更なので、CI の自動テストは書かない。実装の前に次を実行して今の値を確かめ (上の「文脈」の値)、実装の後に `tmux source-file ~/.config/tmux/tmux.conf` をしてからもう一度実行して確かめる。

- `tmux show -gv theme` が、実装の前は `detect`、実装の後は `terminal` であること。
- `tmux -L <名前> -f tmux/tmux.conf` で別のサーバーを起動し、`show -gv theme` が `terminal` であること (設定のファイルから読まれること)。確かめた後、サーバーを止め、`~/.local/run/tmux-501/` のソケットを消す。
- 本人が確かめる: Ghostty の tmux で `Ctrl-T` を押し、ポップアップの背景が灰色でなく、端末の背景と同じ暗い色になる。

## トレードオフ

- tmux 3.8 の組み込みのテーマの色 (256 色で作り直した色) は使わない。3.7 までの、端末の ANSI の色の見た目に戻る。
- 端末を明るいテーマにしても、tmux の色は端末の ANSI の色のまま変わらない。

## 参考文献

- tmux のリポジトリ (ghq で取得、`a73616d`): `CHANGES` の「CHANGES FROM 3.7c TO 3.8」、`options-table.c` (`popup-style`・`popup-border-style`・`theme`・`dark-theme-dark-grey`)、`colour.c` (`colour_theme_table`・`colour_totheme`)、`server-client.c`
- tmux 3.8 の `man tmux` (`theme`、`popup-style`)
- 今の tmux のサーバーでの `tmux show -gv`・`tmux display -p '#{client_theme}'` の結果
