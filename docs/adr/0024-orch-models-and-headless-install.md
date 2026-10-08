# ADR 0024: bin/orch のモデル ID を更新し、画面にログインしていない状態のインストールを最後まで進める

- Status: Accepted
- Date: 2026-10-09
- 関連: docs/audit/2026-10-09-best-practices.md の B6、P1

## Context

- B6: `bin/orch` の別名の既定値が古い (`opus` → `claude-opus-4-8`、`sonnet` → `claude-sonnet-5`、
  `haiku` → `claude-haiku-4-5-20251001`、`fable` → `claude-fable-5`)。現行の最新は
  `claude-opus-5-5`、`claude-sonnet-5-5`、`claude-haiku-5-5`、`claude-fable-5-1` (Claude API のリファレンスで確認)。
  `sol` (`gpt-5.6-sol`) は OpenAI のモデルで、確かめる手段が無い。
- P1: 画面にログインしていない状態 (SSH 越しなど) で `curl | sh` を実行すると、home-manager が colima の LaunchAgent を
  `gui/<uid>` ドメインに登録できず (`Bootstrap failed: 125`)、`bootstrap.sh` が失敗する。`install.sh` はそこで止まり、
  `mise install` まで進まない。登録以外 (パッケージ、GUI アプリ、dotfiles のリンク) は済んでいる。

## Decision

- B6: `opus`・`sonnet`・`haiku`・`fable` の既定値を現行の最新にする。`sol` は推定値のまま残す。
  各既定値は実際に `claude -p --model <ID>` で呼べることを確かめる。従来どおり `ORCH_MODEL_<別名>` で上書きできる。
- P1: `install.sh` で、画面にログインしているか (`launchctl print gui/<uid>` が成功するか) を調べる。
  - ログインしていない状態で `bootstrap.sh` が失敗したときは、警告を出して `mise install` まで続け、最後に
    「画面にログインしてから `sudo darwin-rebuild switch --flake ~/dotfiles#dione` を実行する」よう案内する。
  - ログインしている状態での失敗は従来どおりそこで止める (別の原因の失敗を見逃さないため)。

## Consequences

- `orch` の別名で委譲するモデルが新しくなる (出力の傾向とコストが変わる)。
- 画面にログインしていない状態でも `curl | sh` が最後まで進む。LaunchAgent (colima) の登録だけは、ログイン後の適用で行う。
