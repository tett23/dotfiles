# dotfiles

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/tett23/dotfiles/HEAD/install.sh | sh
```

これだけで以下が完了します (冪等。失敗したら同じコマンドを再実行)。

1. Xcode Command Line Tools
2. `~/dotfiles` への clone (HTTPS) と submodule の取得
3. `bootstrap.sh`: Nix → nix-darwin / home-manager / GUI アプリ / dotfiles のリンク (途中で sudo のパスワードを聞かれます)
4. `mise install`: 言語 / ツール

`DOTFILES` / `DOTFILES_REPO` / `DOTFILES_BRANCH` / `DOTFILES_REMOTE` 環境変数で clone 先などを上書きできます。

clone は SSH 鍵が無くてもできるよう HTTPS で行い、その後 `origin` を SSH の URL
(`git@github.com:tett23/dotfiles.git`) に切り替えます。手元で `git pull` / `push` するには SSH 鍵の設定が必要です
(`install.sh` の再実行は SSH 鍵が無くても動きます)。

## テスト

テストはツールごとに置き場所が違います。CI (`.github/workflows/ci.yml`) では zsh と send-to-kindle のテストを実行します。

| 対象 | 置き場所 | 実行コマンド |
|---|---|---|
| zsh | `zsh/tests/` | `zsh zsh/tests/git-prompt.test.zsh`、`zsh zsh/tests/cached-eval.test.zsh` |
| usage-hint (Claude Code の mod) | `claude/mods/usage-hint/tests/` | `claude plugin test claude/mods/usage-hint` |
| send-to-kindle | `bin/send-to-kindle` の末尾 | `deno test -A --ext=ts bin/send-to-kindle` |

## ドキュメント

現在の仕様は [docs/specifications.md](docs/specifications.md)、依存の一覧は [dependencies.md](dependencies.md)、
設計判断は [docs/adr](docs/adr) を参照。
