# ADR 0016: curl | sh でのインストール後、origin を SSH の URL にする

- Status: Accepted
- Date: 2026-10-07
- Supersedes: ADR 0001 のうち「clone 後の origin は HTTPS のままになる」部分

## Context

ADR 0001 では、SSH 鍵の無い新規マシンでも clone できるよう HTTPS で clone し、`origin` も HTTPS のままにした。
そのため push するには、手で `git remote set-url origin git@github.com:...` を実行する必要があった。

## Decision

- clone は従来どおり HTTPS で行い、その後 `origin` を SSH の URL に切り替える。
  - `DOTFILES_REPO` が `https://github.com/<owner>/<repo>(.git)` の形なら `git@github.com:<owner>/<repo>.git` に変換する。
    それ以外の URL はそのまま使う。
  - 環境変数 `DOTFILES_REMOTE` で切り替え先を直接指定できる。
- 既に clone 済みのとき (再実行時) も、`origin` が異なれば切り替える。
- `install.sh` の中の `git pull` / `submodule update` は従来どおり `url.<https>.insteadOf` でその場だけ HTTPS に読み替えるので、
  SSH 鍵がまだ無い状態で再実行しても失敗しない。

## Consequences

- インストール後すぐに SSH で push できる (SSH 鍵の設定は必要)。
- SSH 鍵を設定するまで、`install.sh` の外での `git pull` / `push` は失敗する。
