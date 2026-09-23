# ADR 0001: `curl | sh` だけでインストールを完了させる

- Status: Accepted
- Date: 2026-09-21

## Context

新しいマシンのセットアップ手順が分散しており、1 コマンドで完了しない。

- `install.sh` は存在しない `Makefile` をダウンロードして `make` しようとするため動かない。
  また `git clone git@github.com:...` は SSH 鍵のない新規マシンでは失敗する。
- 実際に機能しているのは `bootstrap.sh` (Xcode CLT → Nix → nix-darwin 適用) と
  `setup/install.sh` (シンボリックリンク作成) だが、どちらもリポジトリが
  clone 済みであることが前提で、手動で順に実行する必要がある。
- mise 管理の言語・ツール (`mise/config.toml`) は別途 `mise install` が必要。
- submodule (`tmux/tpm`) の URL も SSH で、新規マシンでは取得できない。

リポジトリは public なので、raw.githubusercontent.com からスクリプトを取得できる。

## Decision

`install.sh` を `curl | sh` 用のエントリポイントとして書き直す。

```sh
curl -fsSL https://raw.githubusercontent.com/tett23/dotfiles/HEAD/install.sh | sh
```

`install.sh` は以下を順に実行する。既存の `bootstrap.sh` と `setup/install.sh` は
そのまま再利用し、`install.sh` はそれらを束ねるだけにする。

1. Xcode Command Line Tools を確認し、無ければインストールして完了を待つ (git に必要)
2. `$DOTFILES` (既定 `~/dotfiles`) にリポジトリを **HTTPS** で clone する。
   既にあれば `git pull --ff-only` を試み、失敗しても警告のみで続行する
3. submodule を取得する。`.gitmodules` の SSH URL は、そのコマンド限りの
   `url.<https>.insteadOf` で HTTPS に読み替える (`.gitmodules` 自体は変更しない)
4. `bootstrap.sh` を実行する (Nix → nix-darwin / home-manager / Homebrew Cask)
5. `setup/install.sh` を実行する (シンボリックリンク)
6. `mise install` を実行する (言語・ツール)。失敗は警告に留め、再実行方法を表示する

設計上の制約:

- **POSIX sh で書く。** `| sh` で実行されるため bash 拡張は使わない。
- **全体を `main` 関数で包み、末尾で呼ぶ。** ダウンロードが途中で切れた
  スクリプトが部分的に実行されるのを防ぐ。
- **標準入力に依存しない。** `curl | sh` では stdin がスクリプト本体なので、
  CLT の完了待ちは `read` ではなくポーリングで行い、`bootstrap.sh` には
  `/dev/tty` を stdin として渡す (利用できる場合)。
- **冪等。** 何度実行しても安全で、途中失敗後の再実行で続きから収束する。
- `DOTFILES` / `DOTFILES_REPO` / `DOTFILES_BRANCH` 環境変数で上書き可能にする。

## Consequences

- 新規マシンは 1 コマンドでセットアップが完了する。README もこの 1 行に更新する。
- clone 後の `origin` は HTTPS のままになる。push するには SSH 鍵の設定後に
  `git remote set-url origin git@github.com:tett23/dotfiles.git` が必要。
- `sudo` (nix-darwin の適用) のパスワード入力は依然として対話的に必要。
- `curl | sh` は取得したスクリプトを検証せず実行する方式であり、
  GitHub と TLS を信頼することが前提になる。自分のリポジトリなので許容する。
- macOS (aarch64-darwin, host `dione`) 専用という `bootstrap.sh` の前提は変わらない。
- 動かなくなっていた旧 `install.sh` の Makefile 方式は廃止する。
