# dotfiles

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/tett23/dotfiles/HEAD/install.sh | sh
```

これだけで以下が完了します (冪等。失敗したら同じコマンドを再実行)。

1. Xcode Command Line Tools
2. `~/dotfiles` への clone (HTTPS) と submodule の取得
3. `bootstrap.sh`: Nix → nix-darwin / home-manager / GUI アプリ (途中で sudo のパスワードを聞かれます)
4. `setup/install.sh`: シンボリックリンク
5. `mise install`: 言語 / ツール

`DOTFILES` / `DOTFILES_REPO` / `DOTFILES_BRANCH` 環境変数で clone 先などを上書きできます。

clone 後の `origin` は HTTPS です。SSH 鍵を設定したら切り替えてください。

```sh
git -C ~/dotfiles remote set-url origin git@github.com:tett23/dotfiles.git
```

依存の一覧は [dependencies.md](dependencies.md)、設計判断は [docs/adr](docs/adr) を参照。
