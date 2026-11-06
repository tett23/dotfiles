# ADR 0102: Esc の後の F19 を、NablaSKK の SwitchToAsciiIfIdle (入力中は何もしない) にする

ステータス: 採択

## 文脈

[ADR 0080](0080-escape-to-eisu-in-ghostty.md) と [ADR 0093](0093-escape-sends-f19-for-nablaskk-ascii.md) で、Ghostty の中で Esc を押すと、
Karabiner-Elements が Esc に続けて F19 を送り、NablaSKK のキーマップ (`nablaskk/keymap.conf`) の `SwitchToAscii l||keycode::0x50` で英数モードにしている。

本人から、nvim の挿入モードで NablaSKK の ▼ の変換を Esc で取り消すと、読みが確定して入り、NORMAL に戻ってしまうと報告があった。
原因は、Esc で ▼ が ▽ に戻った直後に、F19 (`SwitchToAscii`) が ▽ の読みを確定して英数モードにすることだった。
これを直すため、NablaSKK に、入力中は何もしない「英数モードへ」の操作 `SwitchToAsciiIfIdle` を足した
(NablaSKK の `docs/adr/0022-switch-to-ascii-if-idle.md`。その ADR の「実装しないこと」で、dotfiles のキーマップは dotfiles の ADR で直すとした)。

調べたことは次のとおり。

- NablaSKK のリポジトリ (ghq で取得、`de158da`): `docs/adr/0022-switch-to-ascii-if-idle.md` は採択で、`SwitchToAsciiIfIdle` は main にマージされている (2026-11-05 14:50)。リリースのタグはまだ無い (最新は `v1.2.4`)。
- 入っている NablaSKK (`~/Library/Input Methods/NablaSKK.app`) は、版の表記が 1.2.4、更新が 2026-11-05 16:24 で、マージより後に作ったものである。実行ファイルに `SwitchToAsciiIfIdle` の文字列がある。
- NablaSKK のエンジンで、既定のキーマップ (`data/keymap.conf`) に dotfiles の `keymap.conf` を設定アプリと同じく `load_replacing` で重ねて、キーを渡した
  (NablaSKK のリポジトリをスクラッチパッドに写し、`crates/nablaskk-core/tests/session_test.rs` に確かめるためのテストを足して `cargo test` で動かした。リポジトリは変えていない)。
  Esc は `hex::0x1b` (`SKK_CANCEL`)、F19 は keycode 0x50 として渡した。

  | 操作 | 今のキーマップ (`SwitchToAscii l\|\|keycode::0x50`) | 新しいキーマップ (`SwitchToAscii l` と `SwitchToAsciiIfIdle keycode::0x50`) |
  | --- | --- | --- |
  | 入力中でないときに Esc、F19 | Esc はアプリへ。F19 で英数モード | 同じ |
  | ▼漢字 で Esc | ▽かんじ (Esc はアプリへ渡らない) | 同じ |
  | 続けて F19 | 「かんじ」を確定して英数モード | ▽かんじ のまま。何も確定しない |
  | 続けて Esc、F19 | Esc はアプリへ (nvim が NORMAL に戻る) | Esc で読みが消える (アプリへ渡らない)。F19 で英数モード |
  | ▽かんじ で `l` | 「かんじ」を確定して英数モード | 同じ |

## 実装すること

- `nablaskk/keymap.conf` の `SwitchToAscii	l||keycode::0x50` を、次の 2 行にする (区切りはタブ。設定アプリが書く形と同じ)。

  ```
  SwitchToAscii	l
  SwitchToAsciiIfIdle	keycode::0x50
  ```

- `docs/specifications.md` の Karabiner の節の、NablaSKK のキーマップの記述を直す (F19 は `SwitchToAsciiIfIdle`。入力中の Esc は NablaSKK が取り消しに使い、英数モードにはならない)。
- Karabiner の設定 (`karabiner/karabiner.json`) は変えない。

## 実装しないこと

- Karabiner の設定の変更。
- NablaSKK のリリースを待つこと。入っている NablaSKK が `SwitchToAsciiIfIdle` を読むことは確かめた (上の「文脈」)。NablaSKK を入れ直す、または古い版に戻すときは、`SwitchToAsciiIfIdle` を含む版にする。

## テスト設計

設定の変更なので、dotfiles の CI の自動テストは書かない。実装の前に次を実行して今の値を確かめ (上の「文脈」の表の左の列)、実装の後にもう一度実行して確かめる (右の列)。

- NablaSKK のエンジンに dotfiles の `keymap.conf` を重ねて、上の表の操作を渡す (スクラッチパッドのテスト)。
- 本人が確かめる (NablaSKK の `docs/adr/0022-switch-to-ascii-if-idle.md` の「作業者が実機で確かめる」と同じ):
  - Ghostty の nvim の挿入モードで ▼漢字 にして Esc を押すと、▽かんじ に戻り、挿入モードのままである。
  - 続けて Esc を押すと、読みが消え、挿入モードのままである。もう一度 Esc を押すと NORMAL に戻り、NablaSKK は英数モードになる。
  - 入力中の文字が無いときに Esc を押すと、今と同じく NORMAL に戻り、英数モードになる。
  - NablaSKK の設定アプリの「キー」ページに、「英数モードへ」が `l`、「英数モードへ (入力中は何もしない)」が F19 と出る。

## トレードオフ

- ▼ の変換から NORMAL に戻るまでの Esc が、2 回から 3 回になる (NablaSKK の `docs/adr/0022-switch-to-ascii-if-idle.md` のトレードオフ)。
- この設定は、`SwitchToAsciiIfIdle` を持たない NablaSKK (リリース済みの `v1.2.4` まで) では、F19 で英数モードにならない。
  `v1.2.4` の `keymap.rs` (`apply`) は、知らない名前の行を読み飛ばすので、F19 はどの操作にも割り当てられず、アプリに届く。

## 参考文献

- NablaSKK のリポジトリ (ghq で取得、`de158da`): `docs/adr/0022-switch-to-ascii-if-idle.md`、`data/keymap.conf`、`crates/nablaskk-core/src/keymap.rs` (`load_replacing`)、`crates/nablaskk-core/tests/session_test.rs`、`v1.2.4` の `crates/nablaskk-core/src/keymap.rs`
- 入っている NablaSKK の `Info.plist` と実行ファイル
- スクラッチパッドで動かした NablaSKK のエンジンの結果
