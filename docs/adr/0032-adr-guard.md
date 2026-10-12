# ADR 0032: adr-guard でコミット済みの ADR の変更を防ぐ

ステータス: 採択

## 文脈

共通の指示 (`.claude/CLAUDE.md`) では、コミット済みの ADR はステータスの行を除いて変更できず、その強制には
adr-guard (https://github.com/tett23/adr-guard) を README に従って導入することになっている。
adr-guard は、git の pre-commit hook・Claude Code の hook・CI の 3 か所で、`docs/adr/` のコミット済みのファイルの変更
(`ステータス:` で始まる行を除く)・削除・名前の変更を拒否する。dotfiles にはまだ導入していない。

導入にあたって、次の 2 つの事情がある。

- **古い書き方の ADR**: [ADR 0001](0001-curl-sh-install.md)〜[0025](0025-send-to-kindle-single-file.md) のステータスの行は `- Status: Accepted` で、adr-guard が許す `ステータス:` で
  始まらない。adr-guard を入れると、これらのステータスは更新できなくなる。
  - 未 push のコミット `fa42bef` ([ADR 0031](0031-command-finder-key-and-rust-tools-via-mise.md) の実装) は、[ADR 0021](0021-modernize-send-to-kindle.md)・0022・0025 のステータスの行を
    `- Status: Accepted → 0031` に変えている。CI の検査範囲にこのコミットが入ると失敗する。
- **公開から間もないリリース**: adr-guard v0.1.0 は 2026-10-11 の公開で、mise の既定の待ち時間 (24 時間) により、
  mise で入れられるのは 2026-10-12 の昼以降になる ([ADR 0031](0031-command-finder-key-and-rust-tools-via-mise.md) の shorten-path と同じ)。

## 実装すること

### 本体を mise で入れる

- `mise/config.toml` の `[tools]` の先頭 (自作のツールの並び) に `"github:tett23/adr-guard" = "latest"` を足す。
  `dependencies.md` の自作のツールの節にも書く ([ADR 0031](0031-command-finder-key-and-rust-tools-via-mise.md) と同じ入れ方)。

### git の pre-commit hook

- `.githooks/pre-commit` を置く (実行権限付き)。

  ```sh
  #!/bin/sh
  exec adr-guard pre-commit
  ```

- `core.hooksPath` はクローンごとの設定のため、`install.sh` で `mise install` の後に
  `git -C "$DOTFILES" config core.hooksPath .githooks` を実行する (この時点で adr-guard が入っている)。
  手で clone した場合の手順は README に書く。
- CI の shellcheck の対象に `.githooks/pre-commit` を足す。

### Claude Code の hook

- `.claude/settings.json` の `hooks.PreToolUse` に、`Write|Edit|MultiEdit` で `adr-guard claude-hook` を実行する hook を足す。
  - `.claude/settings.json` は `~/.claude/settings.json` のリンク元 ([ADR 0030](0030-claude-config-in-dot-claude.md)) なので、全リポジトリで有効になる。
    adr-guard は `docs/adr/` 以外の編集には何もしないため、ほかのリポジトリへの影響は無い。

### CI

- `.github/workflows/ci.yml` に `adr` ジョブを足し、adr-guard の composite action (`tett23/adr-guard@v0.1.0`) で
  push・pull request の範囲のコミットを検査する (README の例のとおり。`fetch-depth: 0`、`persist-credentials: false`)。

### 古い書き方の ADR

- [ADR 0001](0001-curl-sh-install.md)〜[0025](0025-send-to-kindle-single-file.md) は書きかえない (書き方を変えること自体が、コミット済みの ADR の変更になるため)。
  今後これらのステータスは更新しない。置き換えた関係は、新しい ADR の「文脈」に書く。
- `fa42bef` を含む未 push のコミットは、`adr` ジョブを足すコミットより前に push する。
  CI の検査範囲は push ごとの「前回の先頭..今回の先頭」なので、先に push しておけば `adr` ジョブの検査範囲に入らない。

### ドキュメント

- `docs/specifications.md` の ADR の運用の節に、adr-guard で 3 か所で強制していることと、古い書き方の ADR の扱いを書く。
- README に、手で clone したときの `git config core.hooksPath .githooks` の手順を書く。

## 実装しないこと

- 古い書き方の ADR (0001〜0025) の書き換えや、adr-guard 側で `- Status:` の行を許すようにすること。
- 監査レポート (`docs/audit/`) の変更の禁止 (共通の指示ではコミット後は変更不可だが、adr-guard の対象外)。
- `fa42bef` の作り直し (master の rebase は原則禁止のため)。

## テスト設計

- 設定ファイルとシェルスクリプトの変更のため、自動テストは書かない (adr-guard 自体のテストは、そのリポジトリにある)。
- `mise install` の後、次を確かめる。
  - コミット済みの ADR の本文を変えてコミットしようとすると、pre-commit hook が拒否すること。
  - 新しい ADR の追加と、`ステータス:` の行だけの変更はコミットできること。
  - `adr-guard claude-hook` に、コミット済みの ADR を `Edit` する入力 (PreToolUse の JSON) を渡すと拒否し、
    ほかのファイルなら通すこと。
  - `adr-guard check-range` を、`adr` ジョブを足すコミットの前後の範囲で実行して通ること。
- `nix eval` は対象外 (Nix の設定は変えない)。shellcheck が `.githooks/pre-commit` と `install.sh` で通ること。

## トレードオフ

- adr-guard が入っていない間 (新しいマシンで `mise install` を終えるまで、または 2026-10-12 の昼まで) は、
  pre-commit hook がコマンドを見つけられずにコミットを拒否する。
- [ADR 0001](0001-curl-sh-install.md)〜[0025](0025-send-to-kindle-single-file.md) のステータスは今後更新できず、置き換えの関係が古い ADR の側からは分からない。
- 全リポジトリで Claude Code の編集のたびに adr-guard が起動する。
- [ADR 0021](0021-modernize-send-to-kindle.md)・0022・0025 には、adr-guard の規則に反するステータスの変更 (`fa42bef`) が履歴に残る。
