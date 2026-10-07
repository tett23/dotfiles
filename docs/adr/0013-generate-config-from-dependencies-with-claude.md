# ADR 0013: dependencies.md から Claude で設定を生成するスクリプトを置く

- Status: Accepted
- Date: 2026-10-07

## Context

`dependencies.md` が依存の一次ソースで、`flake.nix`・`mise/config.toml`・`nix/pkgs/` はそこから作る実装である。
これまでは対話セッションで sync-deps スキルを使って同期していたため、次の問題があった。

- 同期の手段が対話セッションに限られ、コマンド 1 つで実行できない。
- 実装側 (ADR 0011・0012 の GUI アプリ、自前パッケージ、colima、/etc/zshrc の設定など) にだけ書かれ、
  `dependencies.md` に書かれていない要件があった。

## Decision

- 実装側にだけあった要件を、すべて `dependencies.md` に自然言語で書く。
- `bin/sync-deps` を置く。処理は次のとおり。
  1. `claude -p` (Claude Code の非対話モード) に、`dependencies.md` と現在の実装を読ませて
     `flake.nix`・`mise/config.toml`・`nix/pkgs/` を更新させる。
     同期の手順と名前の対応表は `.claude/skills/sync-deps/SKILL.md` を唯一の情報源とし、
     スクリプトは非対話で動かすための制約だけを指示に足す。
  2. Claude が使えるツールを、ファイルの読み書きと、読み取り・ビルド系のコマンドに絞る。
     `sudo`、`darwin-rebuild`、`git commit` / `push` などは使わせない。
  3. Claude の生成結果は信用せず、スクリプト自身が一般ユーザーで `nix build` して検証する。
  4. 変更の差分を表示する。`--switch` を付けたときだけ適用 (`darwin-rebuild switch` と `mise install`) する。
- 非対話なのでユーザーに確認できない。削除候補や nixpkgs に見つからないパッケージは変更せず、
  Claude の最後の報告に書かせる。
- バージョンの最新化は従来どおり `bin/update-nix` / `bin/update-mise` が行う (役割を分ける)。

## Consequences

- `dependencies.md` を編集して `bin/sync-deps` を実行すれば、設定が生成される。
- 生成は Claude の判断に依存するため、実行のたびに差分を確認する必要がある (スクリプトが差分を表示する)。
- Claude Code (`claude` コマンド) とそのログインが必要になる。
