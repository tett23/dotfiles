# ADR 0003: wget を Nix (home-manager) の CLI 依存に追加する

- Status: Accepted
- Date: 2026-09-23

## Context

`dependencies.md` の "Install CLIs" に `wget` が追記されたが、`flake.nix` の
`home.packages` には含まれていない。他の CLI (curl 等) と同様に宣言的に管理し、
新規マシンでも `darwin-rebuild switch` だけで揃うようにしたい。

- `dependencies.md` は Nix 依存の唯一のソースであり、リストと `flake.nix` の
  乖離は避ける。
- `wget` は nixpkgs に `pkgs.wget` として存在し、追加のオーバーレイは不要。

## Decision

- `flake.nix` の `homeModule` 内 `home.packages` に `pkgs.wget` を追加する。
- CLI は home-manager (darwin モジュール経由) で永続化する既存方針を踏襲し、
  `darwin-rebuild switch --flake .#dione` で適用する。

## Consequences

- `dependencies.md` の CLI リストと `flake.nix` が一致し、`wget` が宣言的に入る。
- `home.packages` は darwin / standalone 双方で共有しているため、
  `home-manager switch --flake .#tett23` 単体でも `wget` が入る。
