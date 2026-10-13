# ADR 0064: adr-guard の pre-commit hook と Claude Code の hook に許可のオプションを付ける

ステータス: 採択

## 文脈

[ADR 0032](0032-adr-guard.md) で adr-guard を導入し、`.githooks/pre-commit` を `exec adr-guard pre-commit`、
`.claude/settings.json` の Claude Code の hook を `adr-guard claude-hook` とした。

adr-guard は v0.5.0 に更新され、手元の adr-guard (mise の `latest`) も v0.5.0 になった。
v0.5.0 では、コミット済みの ADR の次の変更を、オプションを付けたときだけ許可する。

- ステータスの行の変更: `--allow-status` (tett23/adr-guard の [ADR 0010](https://github.com/tett23/adr-guard/blob/main/docs/adr/0010-allow-status-option.md))
- ADR の参照にリンクを付けるだけの変更: `--allow-links` (tett23/adr-guard の [ADR 0009](https://github.com/tett23/adr-guard/blob/main/docs/adr/0009-require-links-for-adr-references.md))

あわせて、v0.4.0 から、pre-commit hook はステージした `.md` のファイルにリンクの無い ADR の参照 (`ADR 0001` の形) があると拒否する。

いまの `.githooks/pre-commit` はオプションを付けていないため、dotfiles で ADR のステータスの行を変えるコミットが止まる。
Claude Code の hook は、`.claude/settings.json` を `adr-guard claude-hook --allow-status` に書きかえ、home-manager で反映済みだが、まだコミットしていない。

## 実装すること

- `.githooks/pre-commit` の最後の行を `exec adr-guard pre-commit --allow-status --allow-links` にする。コメントにこの ADR を足す。
- `.claude/settings.json` の Claude Code の hook を `adr-guard claude-hook --allow-status` にする (反映済みの変更をコミットする)。
- `docs/specifications.md` の ADR の節を、adr-guard が変更を許すのは、ステータスの行 (`--allow-status`) と ADR の参照のリンクだけの変更 (`--allow-links`) であること、
  文書の ADR の参照にはリンクが要ることに合わせて書きかえる。
- [ADR 0032](0032-adr-guard.md) のステータスを `採択→hook のオプションは[ADR 0064](0064-adr-guard-allow-options.md)` にする。

## 実装しないこと

- CI の `adr` ジョブの action (`tett23/adr-guard@v0.1.0`) の更新。v0.1.0 はステータスの行の変更を常に許可し、リンクの検査もしないため、いまの hook の設定と食い違わない。
  CI でもリンクを検査する場合は、別の ADR で v0.5.0 に上げ、`allow-status: true` と `allow-links: true` を付ける。
- `adr-guard links --fix` による既存の文書の修正。いまの文書にリンクの無い参照は無い (`adr-guard links` が終了コード 0)。
- [ADR 0001](0001-curl-sh-install.md)〜[0025](0025-send-to-kindle-single-file.md) の古い書き方 (`- Status:`) のステータスの扱い。[ADR 0032](0032-adr-guard.md) のまま更新しない。

## テスト設計

- 手元の adr-guard (v0.5.0) で、次を確かめる (コミットはしない)。
  - コミット済みの ADR のステータスの行だけを変えてステージすると、`.githooks/pre-commit` が許可する。
  - コミット済みの ADR の本文を変えてステージすると、`.githooks/pre-commit` が拒否する。
  - リンクの無い ADR の参照を含む `.md` をステージすると、`.githooks/pre-commit` が拒否する。
- この ADR の実装のコミットでは [ADR 0032](0032-adr-guard.md) のステータスの行を変えるため、そのコミットが新しい hook を通ることも確かめる。
- CI の shellcheck が `.githooks/pre-commit` で通ることを確かめる。

## トレードオフ

- pre-commit hook がリンクの無い ADR の参照を拒否するため、ADR や仕様を書くときにリンクを付け忘れるとコミットが止まる。`adr-guard links --fix` で直せる。
- CI は v0.1.0 のままのため、`--no-verify` でコミットした場合のステータスの行以外の変更は CI で検出されるが、リンクの付け忘れは CI では検出されない。
- 手元の adr-guard が v0.5.0 より古いと、引数の誤り (終了コード 64) でコミットが止まる。mise の `latest` で入れているため、`mise upgrade` で更新する。
