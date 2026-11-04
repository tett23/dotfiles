# ADR 0080: Ghostty で Esc を押したら、英数キーも送って IME を英数モードにする

ステータス: 採択

## 文脈

本人から、vim で Esc を押したら、IME を英数モードにしたいと要望があった (挿入モードで日本語を入力した後、ノーマルモードのコマンドが
日本語の入力になるのを防ぐため)。

調べた結果は次のとおり。

- 使っている IME は NablaSKK (`jp.tett23.inputmethod.nablaskk`。本人が作っている SKK の IME)。ほかに、ことえり (ローマ字入力) の日本語・英字・カタカナが
  有効になっている。ABC などの英字のキーボード配列の入力ソースは有効になっていない。
- NablaSKK は、ひらがな・カタカナ・英数などのモードを IME の中で切り替え、モードごとの入力ソースを持たない (NablaSKK の `docs/specifications.md`)。
  そのため、`macism` などで入力ソースを選ぶ方法では、NablaSKK の英数モードにはできない (別の入力ソースに切り替わる)。
- NablaSKK は、英数キー (JIS の keycode 0x66) を常に自分で処理する (`AlwaysHandled`) が、既定の割り当てで英数キーを英数モード (`SwitchToAscii`) に
  結び付けていない。キーマップの属性は keycode でも引ける (`nablaskk-core` の `keymap.rs` の `fetch`) ので、ユーザーのキーマップ
  (`~/Library/Application Support/NablaSKK/keymap.conf`) に `SwitchToAscii l||keycode::0x66` を書けば、英数キーで英数モードになるとみられる。
  ことえりは、英数キーで英字に切り替わる。
- Esc を出すキーは 4 つある: Esc キー、`Ctrl-[` (Karabiner の complex_modifications)、左 Option と右 Command (Karabiner の simple_modifications。
  [ADR 0047](0047-ghostty-option-as-alt-removed.md))。Karabiner の設定は `karabiner/karabiner.json` (git で管理し、`~/.config/karabiner` にリンク)。
- nvim の側 (`InsertLeave`) から IME を英数モードにする方法も考えた。`osascript` で英数キーを送るには、Ghostty にアクセシビリティの許可が要り、
  モードを抜けるたびにプロセスを起動する。Karabiner なら、許可も追加のプロセスも要らない。
- Karabiner の規則は、前にある manipulator が先に当たる。simple_modifications と complex_modifications のどちらが先に効いても当たるよう、
  元のキー (左 Option・右 Command) と、変換後の Esc の両方を規則に書く。

## 実装すること

- `karabiner/karabiner.json` の complex_modifications の先頭に、規則「Ghostty で Esc を押したら英数キーも送る」を足す。
  - 条件: 前面のアプリが Ghostty (`frontmost_application_if` の `^com\.mitchellh\.ghostty$`)。
  - manipulator: `escape`・`left_option`・`right_command`・`Ctrl-[` (`open_bracket` + `control`) を、`escape` の後に `japanese_eisuu` を送る形にする。
  - ファイルは Karabiner が書き戻すので、今の書き方 (インデントなど) を崩さないよう、規則だけを差し込む。
- `docs/specifications.md` の Karabiner (または Ghostty) の節に書く。
- NablaSKK のキーマップ (dotfiles の `nablaskk/keymap.conf`。[ADR 0081](0081-nablaskk-config-in-dotfiles.md)) に `SwitchToAscii l||keycode::0x66` を足し、英数キーで英数モードにする。

## 実装しないこと

- NablaSKK の既定のキーマップ (NablaSKK のリポジトリの `data/keymap.conf`) の変更。
- Ghostty 以外のアプリ (VSCode の vim など) での切り替え。
- nvim の `InsertLeave` から IME を切り替えること。
- ssh の先の vim で、手元の IME を切り替えること (Karabiner は手元のキーで動くので、ssh の先でも効く。別の対応は要らない)。

## テスト設計

- Karabiner の設定の変更のため、自動テストは書かない。次を確かめる。
  - `karabiner/karabiner.json` が JSON として読め、`karabiner_cli --lint-complex-modifications` で規則の書き方に誤りが無いこと。
  - 差分が、足した規則だけであること (ほかの規則の書き方が変わっていないこと)。
  - 本人が確かめる: Ghostty の nvim で、NablaSKK のひらがなモードで入力した後に、Esc・左 Option・右 Command・`Ctrl-[` のそれぞれで
    ノーマルモードに戻ると、英数モードになること (NablaSKK に英数キーの割り当てを足した後)。Ghostty 以外のアプリでは、Esc の動きが今と同じこと。
    Karabiner-EventViewer で、Ghostty の中で Esc の後に `japanese_eisuu` が出ること。

## トレードオフ

- Ghostty の中のすべての Esc で英数モードになる (zsh の vi モード・fzf・ほかの TUI も同じ)。
- Esc で、IME の変換中の入力を取り消してから (NablaSKK の `SKK_CANCEL`)、英数モードになる。
- NablaSKK に英数キーの割り当てが無い間は、英数キーは NablaSKK に握りつぶされるだけで、モードは変わらない。

## 参考文献

- Karabiner-Elements の complex_modifications (`frontmost_application_if`、`to` に複数のキー): https://karabiner-elements.pqrs.org/docs/json/
- NablaSKK の `docs/specifications.md`、`data/keymap.conf`、`crates/nablaskk-core/src/keymap.rs` (`~/repositories/src/github.com/NablaSKK`)
