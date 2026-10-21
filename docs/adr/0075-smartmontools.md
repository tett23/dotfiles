# ADR 0075: smartmontools を Nix で入れる

ステータス: 採択

## 文脈

本人から、依存の一覧の Nix (CLI) に smartmontools を足したいと要望があった。smartmontools は、ストレージの SMART の情報
(健康状態・書き込み量・温度など) を読む `smartctl` と、監視の常駐プログラム `smartd` を含む。

- CLI は `dependencies.md` の「Install CLIs」に書き、`flake.nix` の home-manager の `home.packages` で入れる ([ADR 0012](0012-remove-homebrew.md))。
- dotfiles が固定している nixpkgs に `smartmontools` 7.5 があり、`aarch64-darwin` に対応している。cache.nixos.org にビルド済みのものがあった。
- 取得した `smartctl` で `smartctl -H disk0` を実行すると、内蔵の SSD の `SMART overall-health self-assessment test result: PASSED` が、
  sudo 無しで読めた。

## 実装すること

- `dependencies.md` の「Install CLIs」に `smartmontools` を足す。
- `flake.nix` の `home.packages` に `pkgs.smartmontools` を足す。
- 本人が `sudo darwin-rebuild switch --flake ~/dotfiles#dione` で入れる。

## 実装しないこと

- `smartd` (監視の常駐プログラム) を launchd で常駐させること。
- 定期的な検査や通知の設定。

## テスト設計

- 依存の追加のため、自動テストは書かない。次を確かめる。
  - nix-darwin の設定がビルドでき、home-manager のパッケージに smartmontools が含まれること。
  - `darwin-rebuild` の後に、新しい zsh で `command -v smartctl` が Nix の場所を指し、`smartctl -H disk0` で健康状態が読めること。
  - sync-deps の対応表と `dependencies.md`・`flake.nix` が食い違わないこと (名前が同じなので、対応表に足すものは無い)。

## トレードオフ

- 使うときだけのコマンドが、常に PATH に入る。
- 外付けのディスク (USB の変換を通すもの) では、`smartctl` が SMART の情報を読めないことがある。

## 参考文献

- smartmontools: https://www.smartmontools.org/
- smartmontools (nixpkgs): https://search.nixos.org/packages?query=smartmontools
