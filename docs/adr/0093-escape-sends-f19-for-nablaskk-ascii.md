# ADR 0093: Ghostty の Esc で英数キーの代わりに F19 を送り、NablaSKK を英数モードにする

ステータス: 採択

## 文脈

[ADR 0080](0080-escape-to-eisu-in-ghostty.md) で、Ghostty で Esc を押したら、Karabiner が Esc に続けて英数キー (`japanese_eisuu`) を送るようにした。
NablaSKK のキーマップ (`nablaskk/keymap.conf`) には `SwitchToAscii l||keycode::0x66` を書き、英数キーで NablaSKK の英数モードになると見込んでいた。

本人から、vim で INSERT から NORMAL に戻ると、入力が「英字」に変わってしまうと報告があった。調べた結果は次のとおり。

- NablaSKK の診断ログ (`~/Library/Application Support/NablaSKK/debug.log`) では、Ghostty で Esc を押した直後に、前面のアプリが Ghostty のまま
  NablaSKK が deactivate されている。英数キー (keycode 102) は、ログを取り始めてから一度も NablaSKK に届いていない。
- macOS は、英数キーを受けると、ローマ字を打つ入力ソースを選ぶ。NablaSKK は入力モードごとの入力ソースを持たない (NablaSKK の [ADR 0014](https://github.com/tett23/NablaSKK/blob/main/docs/adr/0014-app-and-input-menu-icons.md)) ので、
  有効になっている ことえり の「英字」(`com.apple.inputmethod.Kotoeri.RomajiTyping` の `com.apple.inputmethod.Roman`) に切り替わる。
  これが報告の「英字」である。[ADR 0080](0080-escape-to-eisu-in-ghostty.md) の見込み (英数キーが NablaSKK に届く) は外れていた。
- NablaSKK のキーマップは keycode でもキーを引ける。NablaSKK のエンジンで試すと、`SwitchToAscii` に keycode 0x50 (F19) を割り当てたとき、
  ひらがなモードでは F19 で英数モードになり、キーは IME が処理する (アプリに届かない)。▽ の入力中なら、読みを確定して英数モードになる。
  英数モードでは F19 は処理されず、アプリ (Ghostty) に届く。
- NablaSKK の設定ファイルの `keymap.conf` は、設定アプリの「キー」ページにある操作 (`SwitchToAscii` など) しか読まない。いつも IME が処理する
  キーの属性 (`AlwaysHandled`) は書けないので、英数モードで F19 がアプリに届くのは避けられない。
- 本人の設定の nvim (0.12.6) を headless で起こし、ノーマルモードで `<F19>` と `<S-F7>` (F19 を xterm の流儀で送ると Shift-F7 になる) を入れると、
  どちらも割り当てが無く、カーソルもバッファも変わらなかった。Ghostty が F19 をどう端末に送るか (送るかどうか) は確かめていない。
- Karabiner の設定で、F19 はほかに使っていない。

本人と相談し、NablaSKK は変えずに dotfiles だけで直す方法 (英数キーを、macOS が横取りしない F19 に替える) を選んだ。

## 実装すること

- `karabiner/karabiner.json` の規則「Send eisuu after escape in Ghostty」([ADR 0080](0080-escape-to-eisu-in-ghostty.md)) の 4 つの manipulator で、`to` の `japanese_eisuu` を `f19` に替える。
  規則の説明も、英数キーではなく F19 を送ることに合わせて直す。ほかの規則と書き方 (インデントなど) は変えない。
- `nablaskk/keymap.conf` の `SwitchToAscii l||keycode::0x66` を `SwitchToAscii l||keycode::0x50` にする (英数キーは NablaSKK に届かないので外す)。
- `docs/specifications.md` の Karabiner と NablaSKK の記述を直す。

## 実装しないこと

- NablaSKK に、入力モードごとの入力ソース (英数モードの入力ソース) を足すこと (NablaSKK の [ADR 0014](https://github.com/tett23/NablaSKK/blob/main/docs/adr/0014-app-and-input-menu-icons.md) の決定を覆すため)。
- NablaSKK の `keymap.conf` で `AlwaysHandled` を書けるようにすること (NablaSKK の変更になる。英数モードで F19 がアプリに届くことが
  問題になったら、NablaSKK の ADR として考える)。
- ことえり の入力ソースを無効にすること。
- Ghostty 以外のアプリでの切り替え ([ADR 0080](0080-escape-to-eisu-in-ghostty.md) と同じ)。

## テスト設計

Karabiner と NablaSKK の設定の変更のため、自動テストは書かない。次を確かめる。

- `karabiner/karabiner.json` が JSON として読め、`karabiner_cli --lint-complex-modifications` で規則の書き方に誤りが無いこと。
- 差分が、規則の `japanese_eisuu` を `f19` に替えた部分と説明だけであること。
- 本人が確かめる:
  - Ghostty の nvim で、NablaSKK のひらがなモードで入力した後、Esc・左 Option・右 Command・`Ctrl-[` のそれぞれでノーマルモードに戻ると、
    入力ソースは NablaSKK のまま、NablaSKK の英数モードになること (メニューバーの入力ソースが「英字」に変わらないこと)。
  - 英数モードのまま、ノーマルモードでもう一度 Esc を押しても、nvim に何も起きないこと (F19 が nvim に届いても無害なこと)。
  - zsh のプロンプト・fzf など、Ghostty の中のほかの場面で Esc を押しても、余計な文字が入らないこと。
  - Karabiner-EventViewer で、Ghostty の中で Esc の後に `f19` が出ること。
  - NablaSKK の診断ログに、Esc の後に keycode 80 のキーが記録され、deactivate が起きないこと。

## トレードオフ

- 英数モードでは、F19 が Ghostty を通してアプリに届く。nvim のノーマルモードでは何も起きないことを確かめたが、zsh や fzf などでは
  確かめていない。余計な文字が入るなら、NablaSKK の側で F19 をいつも処理できるようにする必要がある。
- [ADR 0080](0080-escape-to-eisu-in-ghostty.md) の英数キーなら、NablaSKK 以外の IME (ことえり など) でも英字に切り替わったが、F19 は NablaSKK にしか効かない。今使っている IME は
  NablaSKK だけなので、問題にならない。
- Ghostty の中のすべての Esc で F19 を送る点は、[ADR 0080](0080-escape-to-eisu-in-ghostty.md) と同じ。

## 参考文献

- Karabiner-Elements の complex_modifications: https://karabiner-elements.pqrs.org/docs/json/
- NablaSKK の `docs/specifications.md`、`data/keymap.conf`、`macos/Shared/KeymapConfig.swift`、`crates/nablaskk-core/src/session.rs`
  (`~/repositories/src/github.com/NablaSKK`)
- macOS の仮想キーコード (`kVK_F19` = 0x50、`kVK_JIS_Eisu` = 0x66): `HIToolbox/Events.h`
