# ADR 0017: 新規マシンでの nix-darwin の初回適用が失敗する不具合を直す

- Status: Accepted
- Date: 2026-10-08

## Context

macOS の仮想マシン (tart) で README の `curl | sh` を素の状態から実行して検証したところ、
`bootstrap.sh` の nix-darwin の初回適用で止まった。

- darwin-rebuild がまだ無いとき、`bootstrap.sh` は
  `sudo nix run nix-darwin -- switch --flake ... --extra-experimental-features "nix-command flakes"` を実行する。
- 現在の darwin-rebuild は `--extra-experimental-features` を受け付けず、
  `unknown option '--extra-experimental-features'` で終了する。
- 既存のマシンでは darwin-rebuild が既にあるため、この経路は通っていなかった。
- `nix run nix-darwin` はフラグのレジストリから最新の nix-darwin を取得するため、`flake.lock` で固定した版と食い違う。
  `bin/update-nix` と `bin/sync-deps` の初回用の分岐も同じ書き方をしている。

## Decision

- 実験的機能の指定は darwin-rebuild ではなく `nix` コマンドに渡す (`nix --extra-experimental-features ... run`)。
- nix-darwin は `--inputs-from <dotfiles>` で `flake.lock` に固定した版を使う。
- `bootstrap.sh`・`bin/update-nix`・`bin/sync-deps` の初回用の分岐を同じ書き方にそろえる。
- 修正は同じ仮想マシンで再検証する。

## Consequences

- 新規マシンで `curl | sh` が nix-darwin の適用まで進む。
- 初回の適用に使う nix-darwin の版が、`flake.lock` と一致する。
