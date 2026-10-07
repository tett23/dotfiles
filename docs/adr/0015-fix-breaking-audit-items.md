# ADR 0015: 監査の項目のうち、挙動が変わるもの (Z5, I4, O1, M2) を是正する

- Status: Accepted
- Date: 2026-10-07
- 関連: docs/audit/2026-10-07-breaking-changes.md

## Context

docs/audit/2026-10-07-breaking-changes.md に挙げた項目のうち、Z5・I4・O1・M2 を、挙動が変わってもよいとの判断のもとで直す。
M1 (/opt/homebrew の残骸) は本人が手動で削除済み。

## Decision

### V4 の残り (Z5 の前提)
- nvim の rubocop を mason の対象に戻す。mise の Ruby が直ったので gem でインストールできる。
  Z5 で rbenv を消しても nvim の rubocop が使えるようにするため、Z5 より先に行う。

### Z5: 旧ツールのディレクトリ
- `~/.volta`、`~/.rbenv`、`~/.pyenv`、`~/.bun`、`~/.deno`、`~/Library/pnpm` を削除する。
  完全には消さずゴミ箱に移し、必要なら戻せるようにする。グローバルに入れていたコマンドは使えなくなる。

### I4: dotfiles とパッケージの二重管理
- dotfiles のリンクを `setup/install.sh` から home-manager に移す。リンクは
  `mkOutOfStoreSymlink` で dotfiles の実体を直接指し、リポジトリの編集がすぐ反映される従来の挙動を保つ。
  既存のリンクとの衝突で適用が失敗しないよう `home-manager.backupFileExtension` を設定する。
  - リンク先が存在しない `~/.exenv` はやめる。
  - `CLAUDE.md` のリンク (`~/CLAUDE.md`) はやめる。今その場所にファイルは無く、全リポジトリに効く場所
    (`~/.claude/CLAUDE.md`) に置くと、このリポジトリ用の規約が他のリポジトリにも適用されてしまうため。
- `setup/install.sh` を削除し、`install.sh` からの呼び出しもやめる (リンクは `bootstrap.sh` の
  `darwin-rebuild switch` で home-manager が張る)。
- 単体の home-manager (`homeConfigurations`、`~/.nix-profile`) をやめ、nix-darwin の home-manager に一本化する。
  CLI の追加も `darwin-rebuild switch` (sudo) で適用する。sync-deps スキルの手順もこれに合わせる。

### O1: rubocop.yml
- `TargetRubyVersion: 2.5` の指定を削除する。RuboCop がプロジェクトの `.ruby-version` などから判断する。

### M2: 手動で入れた VSCode
- `/Applications/Visual Studio Code.app` をゴミ箱に移し、それを指す `/usr/local/bin/code` を削除する。
  `code` コマンドは Nix 版を使う。

## Consequences

- 旧ツールのグローバルなコマンド (volta の prettier・vivliostyle、deno の自作コマンドなど) と、
  古い Node / Ruby / Python の版は使えなくなる。必要になったら mise か Nix で入れ直す。
- dotfiles のリンクは home-manager が管理する。初回の適用で、既存のリンクは `.hm-backup` を付けて退避される。
- CLI を追加するときも sudo が必要になる。
- `~/.rubocop.yml` を使うプロジェクトで、RuboCop の指摘が変わることがある。
