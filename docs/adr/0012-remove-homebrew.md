# ADR 0012: Homebrew を廃止し、Nix と mise に統一する

- Status: Accepted
- Date: 2026-10-07

## Context

パッケージ管理が Nix (CLI)、mise (言語・ツール)、Homebrew (GUI アプリを nix-homebrew 経由で管理) の 3 つに分かれている。
Homebrew には次の問題がある。

- `homebrew.onActivation.cleanup = "zap"` により、リストから外したアプリがデータごと消える。
- 残っていたフォーミュラ (`gmp` など) が消え、それにリンクしていた mise の Ruby が壊れた。
- codex が Homebrew の Cask と Nix の両方に入っている。

Homebrew で入れている Cask と、Nix での扱い (本人の判断を含む) は次のとおり。

| Cask | Nix での扱い |
|---|---|
| ghostty | nixpkgs の `ghostty-bin` |
| codex | Cask を廃止 (CLI は既に Nix の `codex` がある) |
| claude (デスクトップ) | nixpkgs に無いため、配布 zip から自前で Nix パッケージを作る |
| aquaskk | nixpkgs に無いため、配布 pkg から自前で Nix パッケージを作り、`/Library/Input Methods` に配置する |
| docker-desktop | colima + docker CLI に移行する (Docker Desktop のイメージ・ボリュームは引き継がない) |

手動で入れている VSCode も nixpkgs の `vscode` に移す。Karabiner-Elements はカーネル拡張と権限設定が絡むため手動のままにする。

## Decision

- flake から nix-homebrew と `homebrew` の設定を削除する。GUI アプリは nix-darwin の
  `environment.systemPackages` に入れ、`/Applications/Nix Apps` に置く。
- 自前パッケージ (Claude デスクトップ、AquaSKK) は `nix/pkgs/` に置き、取得元の URL・バージョン・ハッシュを
  `nix/pkgs/sources.json` に書く。最新版は Homebrew の公開 API (formulae.brew.sh。Homebrew 本体は不要) から調べる。
  - Claude デスクトップはアプリ自身の自動更新が効かない (Nix ストアは読み取り専用) ため、更新スクリプトで上げる。
  - AquaSKK は入力メソッドを実体のファイルとして置く必要があるため、nix-darwin のアクティベーションで
    `/Library/Input Methods/AquaSKK.app` にコピーする。
- Docker は home-manager の `services.colima` で colima を常駐させ、docker CLI と compose を Nix で入れる。
- zsh の `brew shellenv` と Homebrew の PATH を削除する。
- 最新化のスクリプトを `bin/` に置く。
  - `bin/update-nix`: `flake.lock` と `nix/pkgs/sources.json` を更新し、`darwin-rebuild switch` で適用する。
  - `bin/update-mise`: mise 管理の言語・ツールを最新化する。
- Homebrew 本体 (`/opt/homebrew`) と Cask で入れたアプリの削除は sudo が必要なので、本人が手順に沿って行う。
  `zap` でデータが消えないよう、Cask の削除は `--zap` を付けずに行う。

## Consequences

- パッケージ管理が Nix と mise の 2 つになる。
- Claude デスクトップと AquaSKK は、更新スクリプトを実行しないと新しい版にならない。
- Docker Desktop のイメージ・ボリューム・コンテナは失われる。
- Karabiner-Elements は引き続き手動管理になる。
- mise の Ruby は、Homebrew の `gmp` にリンクしたビルド済みバイナリが使えないため、別途入れ直す必要がある。
