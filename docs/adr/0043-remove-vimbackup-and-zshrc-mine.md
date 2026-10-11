# ADR 0043: `~/.vimbackup` を作るのをやめ、`.zshrc.mine` を dotfiles に置いてリンクする

ステータス: 採択

## 文脈

ファイル配置の監査 (`docs/audit/2026-10-11-file-layout-2.md`) の次の 2 項目。

- **L17** `flake.nix` の home-manager のアクティベーション (`createVimBackupDirectory`) が、`darwin-rebuild switch` のたびに
  `~/.vimbackup` を作る。nvim は `backup` と `swapfile` を無効にしていて `backupdir` も設定していないので、使われていない
  (中身は空)。旧 vim の設定の名残。
- **L18** `zsh/zshrc` は、dotfiles の外の本人用の設定として `~/.zshrc.mine` を読む (今はファイルが無い)。
  ADR 0042 で、インストーラなどの `~/.zshrc` への追記の代わりに、ここに書くことにした。ホーム直下にあり、XDG に沿っていない。
  - `.zshrc.mine` は、`zsh/zshrc` とは分けておきたい設定 (インストーラの追記など) を書く場所。

## 実装すること

### L17

- `flake.nix` の `home.activation.createVimBackupDirectory` を消す。
- `~/.vimbackup` を削除する (`rmdir`。空のディレクトリ)。

### L18

- dotfiles に `zsh/zshrc.mine` を作って git で管理し、`~/.config/zsh/.zshrc.mine` にリンクする (`flake.nix` の `xdg.configFile`)。
  - 中身は、ファイルの役割を説明するコメントだけにする。dotfiles は公開リポジトリなので、トークンなどの秘密は書かないことも
    コメントに書く。
- `zsh/zshrc` は `${ZDOTDIR:-$HOME}/.zshrc.mine` を読む (`ZDOTDIR` は `~/.config/zsh`。ADR 0042)。従来どおり、ファイルが
  あるときだけ読む。
- `docs/specifications.md` の zsh の節と、配置の表に書く。

## 実装しないこと

- 監査の L19 (ツールのデータの置き場所)。
- `.zshrc.mine` の中身を git で管理しないこと (いったん管理する。分けたくなったら別の ADR にする)。
- 手で clone した場合の手当て (dotfiles は `install.sh` で入れる)。

## テスト設計

- 設定ファイルとシェルスクリプトの変更のため、自動テストは書かない。既存の zsh のテスト (`zsh/tests/`) がすべて通ること。
- `nix eval --raw .#darwinConfigurations.dione.system.drvPath` が通ること。
- `darwin-rebuild switch` の後に、次を確かめる。
  - `~/.config/zsh/.zshrc.mine` が `zsh/zshrc.mine` を指していること。`~/.vimbackup` が作られないこと。
  - `zsh/zshrc.mine` に試しに書いた設定 (環境変数など) が、新しい zsh で効くこと (確かめた後に消す)。

## トレードオフ

- `.zshrc.mine` は公開リポジトリで管理するので、秘密や、そのマシンだけの設定は書けない (書く場合は別の仕組みが要る)。
- インストーラが `~/.zshrc` に追記したものを `.zshrc.mine` に移すと、その内容も公開される。
