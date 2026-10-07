# ADR 0014: 監査の未対応項目のうち、挙動を変えないものを是正する

- Status: Accepted
- Date: 2026-10-07
- 関連: docs/audit/2026-10-07-best-practices.md の未対応 (⬜) 項目

## Context

監査の未対応項目を、「挙動を変えずに直せるもの」と「直すと何かが壊れる・変わるもの」に分ける。
後者は直さず、何が壊れるかを docs/audit/2026-10-07-breaking-changes.md にまとめ、本人が判断する。

## Decision

### 直すもの (挙動を変えない)

- B1: `bin/docker-sh`・`bin/figrm` は bash の構文を使っているので shebang を bash にし、引数をクォートする。
- B2: `bin/rtouch` を POSIX sh として正しく書き直す (`exit -1`、`local`、クォート)。
  失敗時の終了コードは 255 から 1 になるが、呼び出し側で値を見ている箇所は無い。
- B3: `bin/short-pwd` は VSCode のターミナル設定から使われているので削除せず、壊れた shebang だけ直す
  (今は zsh が `/bin/sh` で実行し直しているので動いている)。
- B5 の一部: `bin/send-to-kindle` の `deno.land/std` の dotenv を、後継の JSR の `@std/dotenv` に置き換える
  (同じ `parse` を使う)。権限 (`-A`) と `.env` の読み込み場所は挙動が変わるので変えない。
- I1 / I2: どこからも参照されていない `clean_install.sh`、`setup/install_curl.sh`、
  `setup/detect_package_manager.sh`、空の `docs/ask.md` を削除する。
- N4: nix-darwin の入力元を移転先の `github:nix-darwin/nix-darwin` に変える。ロックは同じリビジョンのまま
  にし、システムのビルド結果が変わらないことを確認する。claude-code の flake の nixpkgs は自分の nixpkgs に
  そろえる (`follows`) が、パッケージのバージョンは変わらない。
- C3 の一部: GitHub Actions の CI を追加する。shellcheck (警告以上)、zsh のテスト、
  nix-darwin の設定の評価 (ビルドはしない) を行う。手元の挙動には影響しない。
- O2 の一部: VSCode の設定から、もう存在しない `go-langserver` の指定 (`go.alternateTools`) を削除する。

### 直さないもの (docs/audit/2026-10-07-breaking-changes.md に報告)

Z5、B5 の残り、B6、I4、C1、C2、C3 の残り、O1、O2 の残り、M1、M2。

## Consequences

- 未対応項目のうち、挙動を変えないものが解消する。
- 残りは報告書を見て、本人が直すかどうかを決める。
