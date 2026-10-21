# ADR 0072: Inkscape を nixpkgs で、prh を mise で入れる

ステータス: 採択

## 文脈

本人から、Inkscape (ベクター画像の編集) と prh (日本語の表記の揺れを辞書で検査・置換する CLI) を入れたいと要望があった。
依存の一覧は `dependencies.md` が一次ソースで、CLI・GUI アプリは Nix、言語とツールは mise で入れる。Homebrew は使わない
([ADR 0012](0012-remove-homebrew.md))。

- **Inkscape**
  - dotfiles が固定している nixpkgs に `inkscape` 1.4.4 があり、`aarch64-darwin` に対応している。cache.nixos.org にビルド済みのものがあり、
    手元でビルドせずに取得できた。中に `Applications/Inkscape.app` がある。
  - Homebrew の cask (公式の dmg) も 1.4.4。nixpkgs に無い GUI アプリは公式の配布物を `nix/pkgs/` で自前のパッケージにしている
    (Claude デスクトップ・AquaSKK) が、Inkscape は nixpkgs にある。
  - GUI アプリは nix-darwin の `environment.systemPackages` で入れ、`/Applications/Nix Apps` に置かれる (ghostty・vscode と同じ)。
- **prh**
  - npm のパッケージ `prh` (6.1.0、MIT。https://github.com/prh/prh)。nixpkgs には無い (`nodePackages` も廃止された)。
  - mise の登録簿には無いが、npm バックエンド (`npm:prh`) で入れられる。TypeScript も同じ入れ方 ([ADR 0062](0062-typescript-7-via-mise.md))。
  - 再実装はしない。辞書の形式 (`prh.yml`) は textlint の `textlint-rule-prh` や各エディタの拡張と共通で、同じ辞書を使い回すには本家と同じ解釈が要るため。

## 実装すること

- `dependencies.md`
  - GUI アプリの一覧に `inkscape` を足す。
  - mise の「Install tools」に `prh` を足し、登録簿に無いので npm バックエンド (`npm:prh`) で入れることを書く。
- `flake.nix` の `environment.systemPackages` に `pkgs.inkscape` を足す。
- `mise/config.toml` に `"npm:prh" = "latest"` を足す。
- sync-deps の名前の対応表 (`.claude/skills/sync-deps/SKILL.md`) に、`inkscape`(GUI) → `pkgs.inkscape` と `prh`(mise) → `"npm:prh"` を書く。
- `mise install` で prh を入れる。Inkscape は本人が `sudo darwin-rebuild switch --flake ~/dotfiles#dione` で入れる。

## 実装しないこと

- 公式の dmg から Inkscape の自前のパッケージを作ること (nixpkgs で足りる。不具合があれば新しい ADR で切り替える)。
- prh の辞書 (`prh.yml`) や、textlint の `textlint-rule-prh` の設定を dotfiles に置くこと。
- prh の再実装。

## テスト設計

- 依存の追加のため、自動テストは書かない。次を確かめる。
  - `nix build` で nix-darwin の設定がビルドでき、生成物に `Inkscape.app` が含まれること。
  - `darwin-rebuild` の後に、`/Applications/Nix Apps/Inkscape.app` があり、起動できること (本人が確かめる)。
  - 新しい zsh で、`command -v prh` が mise の場所を指し、`prh --version` が動くこと。簡単な辞書で、置換の結果が出ること。
  - sync-deps の対応表と `dependencies.md`・`flake.nix`・`mise/config.toml` が食い違わないこと。

## トレードオフ

- nixpkgs の Inkscape は nixpkgs が自前でビルドしたもので、公式の dmg と見た目や挙動に小さな差が出ることがある。版は nixpkgs に合わせて上がる。
- Inkscape の取得で、Nix の store が数百 MB 増える。
- prh は `latest` なので、`bin/update-mise` で上がる。

## 参考文献

- Inkscape (nixpkgs): https://search.nixos.org/packages?query=inkscape
- prh: https://github.com/prh/prh
- mise の npm バックエンド: https://mise.jdx.dev/dev-tools/backends/npm.html
