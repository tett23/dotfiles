# ADR 0095: Ghostty は Cmd+Q を 2 回押したときだけ終了する

ステータス: 採択

## 文脈

Ghostty は Cmd+Q で終了する。終了の確認は出さない設定にしている (`ghostty/config` の `confirm-close-surface = false`)。
そのため、Cmd+Q を誤って押すと、すぐに Ghostty が終了する。
本人から「Cmd+Q を 2 回押さないと閉じない設定にして」と頼まれた。

手元の Ghostty 1.4.0 の説明書き (`ghostty +show-config --default --docs`) で、次を確かめた。

- `keybind` の引き金は、`>` でつないでキーの続き (sequence) にできる (例: `ctrl+a>n=new_window`)。
- 続きの途中では、次のキーを時間切れなしで待つ。続きに無いキーを押すと、続きは取り消され、押したキーはそのまま端末の中のプログラムに送られる。
- 続きの最初のキーにすでに割り当てがあるときは、続きが前の割り当てを上書きする。
- 既定の割り当ては `keybind = super+q=quit`。

設定の写しに `keybind = super+q>super+q=quit` を足して確かめた。

- `ghostty +validate-config` が通る (形の誤った `keybind` は `InvalidFormat` で落ちることも確かめた)。
- `ghostty +list-keybinds --plain` では、`super+q=quit` が消え、`super+q>super+q=quit` だけが出る。

## 実装すること

- `ghostty/config` に `keybind = super+q>super+q=quit` を足す。注釈に、この ADR と、誤って押したときに終了しないためであることを書く。
- `docs/specifications.md` の Ghostty の節に書く。

## 実装しないこと

- 終了の確認のダイアログ (`confirm-close-surface = always`)。ウィンドウやタブを閉じるたびに確認が出るので使わない。
- Cmd+W (ウィンドウ・タブ・分割を閉じる) の変更。
- 1 回目と 2 回目の間の時間切れ (Ghostty に設定が無い)。

## テスト設計

設定の値の変更なので、自動テストは書かない。実装の前に次を実行し、実装の後にもう一度実行して確かめる。

- `ghostty +validate-config` が通ること。
- `ghostty +list-keybinds --plain` で、実装の前は `super+q=quit` が出て、実装の後は `super+q>super+q=quit` だけが出ること。
- 本人が確かめる (Ghostty を起動し直してから):
  - Cmd+Q を 1 回押しても終了しない。続けてもう 1 回押すと終了する。
  - Cmd+Q の後にほかのキーを押すと、終了せず、そのキーが入力される。
  - メニューの「Quit Ghostty」を選ぶと終了する。

## トレードオフ

- 時間切れが無いので、Cmd+Q を 1 回押してしばらく後に Cmd+Q を押しても終了する。
- Cmd+Q を 1 回押した後のキーは、Ghostty の割り当てを経ずにプログラムに送られる。
- macOS のメニューの「Quit Ghostty」に、Cmd+Q のショートカットが残るかどうかは確かめていない。残ってメニューが先に反応する場合は、1 回で終了してしまう。そのときは別の ADR で決める。

## 参考文献

- Ghostty 1.4.0 の `ghostty +show-config --default --docs` (`keybind` の節、`confirm-close-surface` の節)
- Ghostty 1.4.0 の `ghostty +list-keybinds --help`
