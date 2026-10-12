# dotfiles

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/tett23/dotfiles/HEAD/install.sh | sh
```

これだけで以下が完了します (冪等。失敗したら同じコマンドを再実行)。

1. Xcode Command Line Tools
2. `~/dotfiles` への clone (HTTPS)
3. `bootstrap.sh`: Nix → nix-darwin / home-manager / GUI アプリ / dotfiles のリンク (途中で sudo のパスワードを聞かれます)
4. `mise install`: 言語 / ツール
5. ghcup で Haskell の ghc・cabal
6. git の hook (コミット済みの ADR の変更を防ぐ adr-guard)

`DOTFILES` / `DOTFILES_REPO` / `DOTFILES_BRANCH` / `DOTFILES_REMOTE` 環境変数で clone 先などを上書きできます。
`DOTFILES_SKIP_HASKELL=1` で、ghcup での ghc・cabal のインストール (大きい) を省けます。

clone は SSH 鍵が無くてもできるよう HTTPS で行い、その後 `origin` を SSH の URL
(`git@github.com:tett23/dotfiles.git`) に切り替えます。手元で `git pull` / `push` するには SSH 鍵の設定が必要です
(`install.sh` の再実行は SSH 鍵が無くても動きます)。

### 手で clone した場合

コミット済みの ADR の変更を防ぐ git の hook (adr-guard。`mise install` で入る) を有効にします。

```sh
git config core.hooksPath .githooks
```

## テスト

テストはツールごとに置き場所が違います。CI (`.github/workflows/ci.yml`) では zsh のテストを実行します。

| 対象                            | 置き場所                         | 実行コマンド                                                              |
| ------------------------------- | -------------------------------- | ------------------------------------------------------------------------- |
| zsh                             | `zsh/tests/`                     | `for t in zsh/tests/*.test.zsh; do zsh $t \|\| echo "FAIL $t"; done` (1 つだけなら `zsh zsh/tests/<名前>.test.zsh`) |
| usage-hint (Claude Code の mod) | `.claude/mods/usage-hint/tests/` | `claude plugin test .claude/mods/usage-hint`                              |

## ドキュメント

現在の仕様は [docs/specifications.md](docs/specifications.md)、依存の一覧は [dependencies.md](dependencies.md)、
設計判断は [docs/adr](docs/adr) を参照。
