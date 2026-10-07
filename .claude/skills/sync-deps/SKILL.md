---
name: sync-deps
description: dependencies.md を一次ソースとして Nix (flake.nix) と mise (mise/config.toml) の依存を同期・適用・アップデートする。ユーザーが「依存をセットアップして」「dependencies.md を反映して」「パッケージをアップデートして」「nix / mise を更新して」と言ったとき、または dependencies.md を編集した後に必ずこのスキルを使う。セットアップ済みで差分がない場合はパッケージのアップデートを行う。
---

# sync-deps

`dependencies.md` が依存の一次ソース。`flake.nix`(CLI + GUI アプリ)と
`mise/config.toml`(言語・ツール)がその実装。このスキルは
一次ソースと実装の差分を同期し、システムに適用する。

パスはすべて dotfiles リポジトリのルート(このスキルの 2 つ上の階層)からの相対。

## 名前マッピング

dependencies.md の名前と実装側の名前は一致しないものがある。
既知のマッピング:

| dependencies.md | 実装 |
|---|---|
| `rg` | `pkgs.ripgrep` |
| `nvim` | `pkgs.neovim` |
| `awscli` | `pkgs.awscli2` |
| `sed` / `awk` / `make` | `pkgs.gnused` / `pkgs.gawk` / `pkgs.gnumake`(GNU 版指定のため) |
| `claude-code` | `pkgs.claude-code`(claude-code overlay 由来) |
| `docker` / `docker-compose` | `pkgs.docker` / `pkgs.docker-compose`(エンジンは `services.colima`) |
| `colima` | `services.colima.enable = true`(home-manager。パッケージもこれで入る) |
| `ghostty`(GUI) | `pkgs.ghostty-bin`(darwin 向けはこちら) |
| `claude`(GUI) | `claude-desktop`(`nix/pkgs/claude-desktop.nix` の自前パッケージ) |
| `aquaskk`(GUI) | `aquaskk`(`nix/pkgs/aquaskk.nix` の自前パッケージ。アクティベーションで `/Library/Input Methods` にコピー) |
| `vscode`(GUI) | `pkgs.vscode`(unfree) |
| `haskell`(mise) | `ghc` + `cabal` の 2 エントリに展開。`ghc` は `[plugins]` に `ghc = "https://github.com/mise-plugins/mise-ghcup.git"` を明示する(プラグイン名がツール名になるため。docs/adr/0018) |

未知のパッケージが出てきたら `nix search nixpkgs <name>` で attr 名を
確認してから追加する。見つからない場合は勝手に近い名前で代用せず、
ユーザーに確認する。

非対話で同期する場合は `bin/sync-deps` を使う(`claude -p` でこのスキルの手順 1〜2 を実行し、
スクリプトが `nix build` で検証して差分を表示する。`--switch` で適用まで行う。docs/adr/0013)。

## 手順

### 1. 差分検出

`dependencies.md`、`flake.nix`、`mise/config.toml` を読み、
マッピングを考慮して 3 つのリストを突き合わせる:

- **CLI** → `flake.nix` の `home.packages`
- **GUI apps** → `flake.nix` の `environment.systemPackages`(Homebrew は使わない)
  - nixpkgs に無いものは `nix/pkgs/<name>.nix` に自前で作り、取得元を `nix/pkgs/sources.json` に書く
- **言語・ツール** → `mise/config.toml` の `[tools]`(バージョンは `"latest"`)

### 2. 同期

- 足りないものは追加する。
- 実装側にあって dependencies.md にないものは**勝手に削除しない**。
  削除候補として提示し、ユーザーの承認を得てから消す。

### 3. 適用

変更した範囲だけ適用する:

- **mise**: `mise install` (新規追加時)
- **Nix の変更 (CLI・GUI アプリとも)**: `darwin-rebuild switch` が必要で sudo を要する。
  home-manager は nix-darwin のモジュールとしてだけ使う (単体の `home-manager switch` は使わない。docs/adr/0015)。
  自分では実行せず、ユーザーにこのコマンドの実行を提案する:
  ```
  ! sudo darwin-rebuild switch --flake ~/dotfiles#dione
  ```

### 4. アップデート(差分がなかった場合)

セットアップ済みで同期差分がない場合はアップデートを行う。
どちらも本人に実行を提案する (`bin/update-nix` は sudo を要する):

```bash
bin/update-nix    # flake.lock と nix/pkgs/sources.json を更新し、ビルドしてから darwin-rebuild switch で適用
bin/update-mise   # mise 管理の言語・ツールを latest に
```

### 5. 検証

適用後に実際にコマンドが引けることを確認する:

```bash
command -v <追加したコマンド>
mise ls --current
```

## 初回セットアップ(nix が無い場合)

`command -v nix` が失敗する場合は初回セットアップ。`bootstrap.sh` が
Nix インストール → nix-darwin 適用まで冪等に行うが、対話入力
(Xcode CLT の完了待ち・sudo)を含むためユーザーに実行を提案する:

```
! ./bootstrap.sh
```

## 注意

- `flake.nix` の構造(overlay、home-manager モジュール)は変更しない。触るのは
  `home.packages`、`environment.systemPackages`、`services.colima` などのパッケージの指定と、
  `dependencies.md` の「自前パッケージ」「システム設定」の節に書かれた設定
  (`nix/pkgs/`、AquaSKK のアクティベーション、`programs.zsh` の設定など)だけ。
- Homebrew は使わない。nixpkgs に無い GUI アプリはユーザーに確認してから `nix/pkgs/` に自前で作る。
- `mise/config.toml` のバージョンは常に `"latest"`。特定バージョンへの
  固定を求められた場合のみ例外。
- 適用まで完了したら、変更ファイル(`flake.nix`, `flake.lock`,
  `mise/config.toml`)の diff を要約して報告する。コミットは求められた
  場合のみ。
