# ADR 0081: NablaSKK の設定ファイルを dotfiles で管理する

ステータス: 採択→トレードオフ (設定アプリで保存するとリンクが外れる) は [ADR 0086](0086-nablaskk-keeps-config-links.md)

## 文脈

本人から、NablaSKK (本人が作っている SKK の IME) の設定ファイルを dotfiles に移し、シンボリックリンクを張りたいと要望があった。
[ADR 0080](0080-escape-to-eisu-in-ghostty.md) で、NablaSKK のキーマップに英数キーの割り当てを足すことになり、その設定も dotfiles で持てるようにする。

- NablaSKK の設定の置き場所は `~/Library/Application Support/NablaSKK/`。中身は次のとおり。
  - 設定: `keymap.conf` (キーの割り当ての差分)・`kana-rule.conf` (ローマ字かなの規則)・`settings.conf` (入力の設定)・`dictionaries.conf` (辞書の一覧)。
    どれも数百〜1000 バイトで、秘密は含まない。`dictionaries.conf` には辞書のファイルの絶対パス (`/Users/tett23/…`) が入っている。
  - 設定ではないもの: `skk-jisyo` (ユーザーの辞書。打った言葉が入る)、`dictionaries/` (ダウンロードした辞書)、`debug.log` (129MB)・`debug-enabled`。
- AquaSKK のキーマップは、すでに dotfiles の `skk/keymap.conf` を `~/Library/Application Support/AquaSKK/keymap.conf` にリンクしている
  (home-manager の `home.file` と `mkOutOfStoreSymlink`)。
- home-manager は `backupFileExtension = "hm-backup"` なので、リンクを張る場所に既にファイルがあると、`<名前>.hm-backup` に退避してからリンクを張る。
- NablaSKK の設定アプリは、4 つのファイルを `write(to:atomically: true)` で書く (NablaSKK の `macos/Shared/*Config.swift`・`InputSettings.swift`)。
  この書き方は、一時ファイルに書いてから置き換えるので、シンボリックリンクが普通のファイルに置き換わる。dotfiles のファイルは変わらず、
  次の `darwin-rebuild switch` で、設定アプリで変えた内容が `.hm-backup` に退避され、dotfiles の内容に戻る。
- dotfiles は公開のリポジトリ。

## 実装すること

- `nablaskk/` を作り、今の 4 つの設定ファイル (`keymap.conf`・`kana-rule.conf`・`settings.conf`・`dictionaries.conf`) を写す。
- `flake.nix` の `home.file` に、`Library/Application Support/NablaSKK/<名前>` → `nablaskk/<名前>` のリンクを 4 つ足す (AquaSKK と同じ書き方)。
- 本人が `sudo darwin-rebuild switch --flake ~/dotfiles#dione` を実行する。今のファイルは `.hm-backup` に退避される。
- `docs/specifications.md` の設定ファイルの配置の表に足し、設定アプリで変えると、リンクが外れることを書く。

## 実装しないこと

- `skk-jisyo`・`dictionaries/`・`debug.log`・`debug-enabled` を dotfiles に入れること (個人の情報・大きいファイル・作業用のファイルのため)。
- NablaSKK の設定アプリを、シンボリックリンクの先に書くように直すこと (NablaSKK のリポジトリで扱う)。
- `dictionaries.conf` の絶対パスを、ほかのマシン向けに書き換えること (このマシンの利用者名のまま)。

## テスト設計

- 設定ファイルの移動のため、自動テストは書かない。次を確かめる。
  - `nablaskk/` の 4 つのファイルが、今のファイルと同じ内容であること (`cmp`)。
  - `nix build` で nix-darwin の設定がビルドでき、生成物の home-manager のファイルに 4 つのリンクが含まれること。
  - `darwin-rebuild` の後に、4 つのファイルが dotfiles へのシンボリックリンクになり、`.hm-backup` が残っていること (本人が実行した後に確かめる)。
  - 本人が確かめる: NablaSKK で入力でき、ローマ字かなの規則 (`fj` → `、` など) と辞書が今までどおり効くこと。

## トレードオフ

- NablaSKK の設定アプリで設定を変えると、リンクが普通のファイルに置き換わる。次の `darwin-rebuild switch` で、その変更は `.hm-backup` に退避され、
  dotfiles の内容に戻る。設定は dotfiles のファイルを直接編集する (または NablaSKK 側で、リンクの先に書くよう直す)。
- `dictionaries.conf` の絶対パスで、利用者名 (`tett23`) が公開される (flake の設定などで既に公開している)。

## 参考文献

- home-manager の `home.file`・`mkOutOfStoreSymlink`・`backupFileExtension`: https://nix-community.github.io/home-manager/options.xhtml
- NablaSKK の `docs/specifications.md` の「5. 設定ファイル」、`macos/Shared/KeymapConfig.swift` など (`~/repositories/src/github.com/NablaSKK`)
- Apple の `String.write(to:atomically:encoding:)`: https://developer.apple.com/documentation/foundation/nsstring/write(to:atomically:encoding:)
