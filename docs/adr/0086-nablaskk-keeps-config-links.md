# ADR 0086: NablaSKK の設定アプリで保存しても、設定ファイルのリンクが外れなくなったことを反映する

ステータス: 採択

## 文脈

[ADR 0081](0081-nablaskk-config-in-dotfiles.md) で、NablaSKK の設定ファイル 4 つ (`keymap.conf`・`kana-rule.conf`・`settings.conf`・`dictionaries.conf`) を
dotfiles の `nablaskk/` からリンクした。そのトレードオフに、「NablaSKK の設定アプリで設定を変えると、リンクが普通のファイルに置き換わる。
次の `darwin-rebuild switch` で、その変更は `.hm-backup` に退避され、dotfiles の内容に戻る」と書いた。
実際に 2026-11-04 に `kana-rule.conf` のリンクが外れ、dotfiles に手で取り込んでリンクを張り直した。

その後、本人が NablaSKK を直した (NablaSKK のリポジトリの `docs/adr/0021-keep-symlinked-config-files.md`「シンボリックリンクの設定ファイルをリンクのまま保つ」、コミット `89b9f00`)。

- 設定アプリと IME は、保存するときにリンクを最後まで辿り、その先のファイルに書く (`macos/Shared/ConfigFile.swift` の `resolvingLinks`・`write`)。
  この dotfiles では、`NablaSKK/<名前>` → home-manager のファイル (Nix ストア) → `~/dotfiles/nablaskk/<名前>` と辿り、dotfiles のファイルを書き換える。
  ユーザーの辞書 (`skk-jisyo`) も同じ。リンクの先が書けないと、設定アプリに「保存できません」と出る (NablaSKK の README)。
- 直したものは、NablaSKK のリポジトリのブランチ `keep-symlinked-config` にあり、まだリリースしていない (最新のリリースは 1.2.3 で、直す前のもの)。
  本人が、このブランチからビルドした `NablaSKK.app` (2026-11-05 04:18) を `~/Library/Input Methods/` に入れた。
  IME と設定アプリの実行ファイルに `ConfigFile.resolvingLinks` があることを `nm` で確かめた。
- 2026-11-05 に、本人が設定アプリの「入力」ページで句点を切り替えると、`~/dotfiles/nablaskk/settings.conf` が書き換わり (`period=japanese` → `period=fullwidth`)、
  4 つのファイルはリンクのままだった。元に戻すと、差分は無くなった。
- リンクが外れなくなったので、`.hm-backup` に退避したもの (2026-11-04 の `darwin-rebuild` で退避した、移す前のファイル 4 つ) は要らなくなった。
  本人の了承を得て、ゴミ箱に移した。

## 実装すること

- [ADR 0081](0081-nablaskk-config-in-dotfiles.md) のステータスを「採択→トレードオフ (設定アプリで保存するとリンクが外れる) は ADR 0086」にする。
- `docs/specifications.md` の設定ファイルの配置の表の NablaSKK の行を、「設定アプリで保存すると、リンクの先 (dotfiles の `nablaskk/`) のファイルが
  書き換わる。リンクのまま保つのは、NablaSKK の `docs/adr/0021-keep-symlinked-config-files.md` を入れた版から」にする。
- `flake.nix` の NablaSKK のリンクの注釈を、「設定アプリで保存すると、dotfiles のファイルが書き換わる」にする。

## 実装しないこと

- ユーザーの辞書 (`skk-jisyo`) を dotfiles で管理すること ([ADR 0081](0081-nablaskk-config-in-dotfiles.md) のとおり、個人の情報のため入れない)。
- NablaSKK のアプリを Nix で入れること。
- 直す前の版 (1.2.3 までのリリース) を入れたときに備えること (その版では、今までどおり保存でリンクが外れる)。

## テスト設計

- 文書と注釈の変更のため、自動テストは書かない。次を確かめる。
  - [ADR 0081](0081-nablaskk-config-in-dotfiles.md) の差分が、ステータスの行だけであること (adr-guard の pre-commit が通ること)。
  - `adr-guard links` と `adr-guard check-status` が何も報告しないこと。
  - `nix build` で nix-darwin の設定がビルドできること (注釈しか変えないので、生成物は変わらない)。
- 保存してもリンクが外れないことは、上の「文脈」のとおり、本人が設定アプリで切り替えて確かめた。

## トレードオフ

- 設定アプリで保存すると、dotfiles の作業ツリーの `nablaskk/` に差分が出る。残すならコミットし、要らなければ戻す。
  設定アプリが、中身を変えずに並びだけ変えて保存することがある (2026-11-05 に `kana-rule.conf` の行の順が変わった)。
- 直したものがリリースされるまでは、リリースの版 (`install.sh`) を入れ直すと、保存でリンクが外れる動きに戻る。

## 参考文献

- NablaSKK のリポジトリ (`~/repositories/src/github.com/NablaSKK`。ブランチ `keep-symlinked-config`) の `docs/adr/0021-keep-symlinked-config-files.md`、
  `macos/Shared/ConfigFile.swift`、README の設定ファイルの節: https://github.com/tett23/NablaSKK
