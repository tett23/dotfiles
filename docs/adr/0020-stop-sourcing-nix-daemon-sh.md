# ADR 0020: zsh で nix-daemon.sh を読み込まない

- Status: Accepted
- Date: 2026-10-08

## Context

Ghostty + tmux の中で `bat RE<Tab>` と補完すると、`_bat: function definition file not found` になった。

- tmux の中の zsh は、tmux サーバーが起動時に引き継いだ環境で起動する。
- `zsh/exports.sh` が読み込む Nix 本体のスクリプト (`/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`) は、
  `NIX_PROFILES` を `/nix/var/nix/profiles/default ~/.nix-profile` に上書きする。nix-darwin が設定する値から
  `/run/current-system/sw` と `/etc/profiles/per-user/$USER` (home-manager のパッケージ) が抜けている。
- tmux の中の子シェルは、nix-darwin の `/etc/zshenv` で `__NIX_DARWIN_SET_ENVIRONMENT_DONE` も引き継ぐため、
  正しい `NIX_PROFILES` に戻さない。`/etc/zshenv` は `NIX_PROFILES` から `fpath` を作るので、home-manager で入れた
  パッケージの補完 (`_bat` など) が `fpath` から外れる。
- これまで動いていたのは、単体の home-manager の環境 (`~/.nix-profile`) に補完が入っていたため。
  ADR 0015 でその環境を廃止したことで問題が表に出た。
- nix-darwin の `/etc/zshenv` (set-environment) は、Nix に必要な `PATH`・`NIX_PROFILES`・`NIX_SSL_CERT_FILE` を
  すべて設定している。nix-daemon.sh は Nix 本体を Determinate が管理するようになる前の名残で、追加しているものは無い。

## Decision

- `zsh/exports.sh` から nix-daemon.sh の読み込みを削除し、Nix の環境は nix-darwin の `/etc/zshenv` に任せる。
- `bootstrap.sh` の nix-daemon.sh の読み込みは、nix-darwin を適用する前に nix を使うためのものなので残す。

## Consequences

- tmux の中など、環境を引き継いだシェルでも `NIX_PROFILES` と `fpath` が正しくなり、補完が見つかる。
- 既に起動している tmux サーバーは古い環境を持っているので、再起動するか環境変数を直す必要がある。
