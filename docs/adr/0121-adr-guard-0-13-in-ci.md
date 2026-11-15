# ADR 0121: CI の adr-guard を 0.13.1 に上げ、ADR のステータスの行を新形式に移す

Status: proposed

## 文脈

[ADR 0066](0066-adr-guard-0-8-in-ci.md) で、CI の `adr` ジョブを `tett23/adr-guard@v0.8.0` にした。手元の adr-guard は mise の `latest` で入り (`mise/config.toml`)、いまは 0.13.1 である。
pre-commit hook は `adr-guard pre-commit --allow-status --allow-links`、Claude Code の hook は `adr-guard claude-hook --allow-status`、
Codex の hook は `adr-guard codex-hook --allow-status` ([ADR 0115](0115-codex-adr-guard-hook.md)) を動かす。

adr-guard は、0.8.0 の後に次の変更を出した。

| 版 | 変更 |
| --- | --- |
| 0.9.0、0.9.1 | 同じディレクトリで番号が重複した ADR を報告する `adr-guard check-numbers` を足した。action は既定でこれを実行する。番号を振りなおす `adr-guard renumber` と、振りなおしを認める `--allow-renumber` も足した ([tett23/adr-guard ADR 0018](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0018-repair-duplicate-adr-numbers.md)) |
| 0.10.0 | `ADR NNNN` の直前の語を、ディレクトリやモジュールの修飾子として読む ([tett23/adr-guard ADR 0019](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0019-module-qualified-adr-references.md))。シンボリックリンクの `.md` を検査しない ([tett23/adr-guard ADR 0020](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0020-skip-symlinked-documents.md)) |
| 0.11.0 | Codex の PreToolUse hook `adr-guard codex-hook` を足した ([tett23/adr-guard ADR 0021](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0021-codex-hook.md)) |
| 0.12.0 | ステータスの行の新形式と、状態の遷移の検査を足した ([tett23/adr-guard ADR 0022](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0022-status-transitions.md))。修正の連なりをたどる `adr-guard trace` を足した ([tett23/adr-guard ADR 0023](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0023-trace-amendments.md)) |
| 0.13.0 | 移行のスクリプトに `--dry-run` を足し、移せない ADR を全件数えるようにした ([tett23/adr-guard ADR 0024](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0024-migration-dry-run-and-error-count.md))。新形式に `superseded-pending`、変更の種類 `kind` (`replace`、`supplement`、`note`) と注記 `note`、`https://` の修正先を足した ([tett23/adr-guard ADR 0025](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0025-extend-canonical-status-amendments.md))。旧形式の参照の読み方を広げた ([tett23/adr-guard ADR 0026](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0026-read-more-legacy-references.md)、[tett23/adr-guard ADR 0027](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0027-read-legacy-replaced-status.md)) |
| 0.13.1 | 旧形式の部分の名前から、`ADR NNNN` の直前の修飾子、先頭の `。`、末尾の `→` を除くようにした。参照の後ろに部分の名前の続きがある行と、括弧が部分の名前をまたぐ行は、移行スクリプトが「部分名を決められません」と報告し、移せない ADR として数える ([tett23/adr-guard ADR 0028](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0028-fix-legacy-part-names.md)) |

新形式のステータスの行は `Status: <トークン>` である。トークンは `proposed`、`accepted`、`accepted-pending`、`superseded-pending`、`rejected`、`discarded`、`deprecated`、
または `superseded [<変更の JSON 配列>]` とする。変更の要素は `{"part":<部分の名前か null>,"by":[<リポジトリのルートからのパス>]}` である。

[tett23/adr-guard ADR 0022](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0022-status-transitions.md) によれば、0.12.0 からは、追加した ADR と、ステータスの行を変えた ADR に新形式が要る。
pre-commit hook と `check-range` は状態の遷移も検査し、遷移の検査は `--allow-status`、`ADR_GUARD_ALLOW`、トレーラーでは免除されない。旧形式の行は、変えないかぎりそのまま読める。

このため、手元の hook (0.13.1) と CI (0.8.0) では、ADR の検査が食い違っている。手元では新形式が要り、CI は新形式の遷移も番号の重複も検査しない。
また、ADR のステータスの行は、`ステータス: 採択→…は[ADR NNNN](…)` と `Status: Accepted` などの旧形式が混ざっている。

## 調査した事項

この節の確認は、手元の adr-guard 0.13.1 (`adr-guard -V` が `adr-guard 0.13.1` を出す) と、adr-guard の v0.13.1 のソースの `scripts/migrate-adr-status` (以下、移行スクリプト。リリースのアーカイブには入らない) で行った。

- action の入力は、0.8.0 から 0.13.1 までに `check-numbers` (既定は `"true"`) と `allow-renumber` (既定は `"false"`) が増えた。ほかの入力は変わっていない
  (tett23/adr-guard のクローンでの `git diff v0.8.0 v0.13.0 -- action.yml` と、`git diff --quiet v0.13.0 v0.13.1 -- action.yml` の終了コード 0)。
  0.13.1 の action は、`version` を省くと、action のコミットの `Cargo.toml` の版 (`0.13.1`) のリリースを取得する。
- このブランチの作業ツリーで、`adr-guard links`、`adr-guard check-status`、`adr-guard check-numbers` は、どれも終了コード 0 で終わった。`adr-guard links --fix --include-committed` は、どのファイルも書きかえなかった。
  0.10.0 の修飾子付きの参照の規則と、0.9.0 の番号の重複の検査は、いまの文書と ADR では違反を出さない。
- 移行スクリプトの `--dry-run` は、移せる ADR を 117 件、移せない ADR を 3 件と数え、終了コード 1 で終わった (このほかに、`Status: proposed` のこの ADR を移行済みの 1 件と数えた)。移せない 3 件は、
  [ADR 0021](0021-modernize-send-to-kindle.md)、[ADR 0022](0022-send-to-kindle-env-file-option.md)、[ADR 0025](0025-send-to-kindle-single-file.md) の `Status: Accepted → 0031` である。
  スクリプトは、この形を「注記または未知のステータス」として変換しない。[ADR 0031](0031-command-finder-key-and-rust-tools-via-mise.md) は、この 3 件のステータスを「採択→0031」にすると定めている。
  「部分名を決められません」と報告された ADR はなかった。
- 移行スクリプトの `--write` は、移せない ADR が 1 件でもあると、どのファイルも書きかえず、終了コード 1 で終わった (このリポジトリの写しで、3 件を直す前に実行した)。
- このリポジトリの写しで、0.13.1 の pre-commit hook は、新しい ADR の `ステータス: 提案` を拒否した (「新形式のステータス行は `Status: ` で始めてください」)。
  追加の時点での `Status: accepted` も拒否し (「許可されていない状態遷移: Absent -> accepted」)、`Status: proposed` は通した。
  これまでの ADR は、[ADR 0066](0066-adr-guard-0-8-in-ci.md) のように `ステータス: 採択` で最初にコミットしてきた (`git show a4f5b5b:docs/adr/0066-adr-guard-0-8-in-ci.md` の 3 行目)。0.13.1 では、この手順は拒否される。
- 移行の全体は、このリポジトリの写しで確かめた。写しには、この ADR の草稿を置いてコミットした。続けて 3 件を下の行に手で書き、`--write` を実行し、
  [ADR 0066](0066-adr-guard-0-8-in-ci.md) の行を下のとおりに直した。その後の `--dry-run` は「移行できる: 0件、移行済み: 121件、移行できない: 0件」を出した。
  変更をコミットすると pre-commit hook が通り、`adr-guard check-range --allow-status --allow-links <元の HEAD> HEAD`、`check-status`、`links`、`check-numbers` は、どれも終了コード 0 で終わった。
  移行の後の 121 件は、`accepted` が 102 件、`superseded` が 15 件、`discarded` が 2 件、`rejected` が 1 件、`proposed` が 1 件だった。
  `adr-guard trace docs/adr/0066-adr-guard-0-8-in-ci.md` は、この ADR への `CI の adr-guard の版` の置換の辺を出した。

## 実装すること

- `.github/workflows/ci.yml` の `adr` ジョブを `tett23/adr-guard@v0.13.1` にする。入力 (`base`、`head`、`allow-status: true`、`allow-links: true`) は変えない。
  `check-numbers` と `allow-renumber` は指定せず、既定 (番号の重複を検査し、振りなおしは許可しない) に従う。ジョブのコメントに番号の重複と状態の遷移の検査を書き、ADR の番号に 0121 を足す。
- ステータスの行を、この ADR を `Status: proposed` でコミットした後に、次の順で新形式に移す。
  1. [ADR 0021](0021-modernize-send-to-kindle.md)、[ADR 0022](0022-send-to-kindle-env-file-option.md)、[ADR 0025](0025-send-to-kindle-single-file.md) のステータスの行を、手で
     `Status: superseded [{"by":["docs/adr/0031-command-finder-key-and-rust-tools-via-mise.md"],"part":null}]` にする。
  2. リポジトリのルートで、adr-guard の v0.13.1 のソースの `scripts/migrate-adr-status` を `--dry-run` で実行し、移せない ADR が 0 件であることを確かめてから、`--write` で書く。
  3. [ADR 0066](0066-adr-guard-0-8-in-ci.md) のステータスを `Status: superseded [{"by":["docs/adr/0121-adr-guard-0-13-in-ci.md"],"part":"CI の adr-guard の版"}]` にする。
- `docs/specifications.md` を直す。
  - CI の節: adr-guard が、番号の重複 (`check-numbers`) と状態の遷移も検査することを書き、ADR の番号に 0121 を足す。
  - ADR の運用の節: ステータスの行の新形式 (トークンと変更の JSON 配列) を書く。新しい ADR は `Status: proposed` でコミットし、追加の時点では `accepted` にできないこと、
    旧形式の行は変えないかぎり読めること、`adr-guard trace` で修正の連なりをたどれること、ADR の番号を重複させないこと、修飾子付きの参照の規則を書く。
    [ADR 0001](0001-curl-sh-install.md)〜0025 の「値は `Accepted` などのまま」の記述は、この ADR で新形式に移したことに改める。
- `adr-guard links --fix --include-committed` を実行し、直すべき参照があれば直す。

## 実装しないこと

- 手元の hook (`.githooks/pre-commit`、`.claude/settings.json`、`codex/hooks.json`) のコマンドの変更。0.13.1 でもそのまま使える。Codex の hook は [ADR 0115](0115-codex-adr-guard-hook.md) ですでに動かしているので、この ADR では足さない。
- `mise/config.toml` の adr-guard の指定 (`latest`) の変更。手元はすでに 0.13.1 で、README の手順も変わらない。
- action の版を `latest` などで追うことと、コミットの SHA での固定 ([ADR 0066](0066-adr-guard-0-8-in-ci.md) と同じく、版のタグで参照する)。
- 全体の指示 (`.claude/CLAUDE.md` と `codex/AGENTS.md`) の ADR の構成の例のステータスの行 (`ステータス: {採択／…}`) を新形式に改めること。全リポジトリの ADR の書き方を決める変更なので、別の ADR で扱う。
- ADR の本文の変更。変えるのはステータスの行だけとする。
- 移行スクリプトをこのリポジトリに取り込むこと。移行は一度だけの作業のため。

## 不変条件

なし。設定の値と、一度だけ行う移行の手順を決める ADR で、このリポジトリのスクリプトや設定の振る舞いを変えないため。

## テスト設計

- 設定と文書とステータスの行の変更のため、自動テストは書かない。次を確かめる。
  - `.github/workflows/ci.yml` が YAML として読め、`adr` ジョブの `uses` と `with` が上のとおりであること。
  - 移行の後に、移行スクリプトの `--dry-run` が「移行できない: 0件」を出し、`grep -l '^ステータス:' docs/adr/*.md` が何も出さないこと。
  - 手元で、`adr-guard links`、`adr-guard check-status`、`adr-guard check-numbers` が成功し、移行の変更をステージした状態で `.githooks/pre-commit` が通ること。
  - コミットの後、action と同じ検査 (`adr-guard check-range --allow-status --allow-links <push の前の origin/master> HEAD`) が成功すること。
  - `adr-guard trace docs/adr/0066-adr-guard-0-8-in-ci.md` が、この ADR への辺を出すこと。
  - push の後に、GitHub Actions の `adr` ジョブが 0.13.1 の action で成功すること。

## トレードオフ

- 新しい ADR は、まず `Status: proposed` でコミットし、採択は別のコミットでステータスの行を変えて記録することになる。[ADR 0066](0066-adr-guard-0-8-in-ci.md) のように最初から `採択` でコミットする手順は使えなくなるが、採択や却下が状態の遷移として検査される。
- [ADR 0066](0066-adr-guard-0-8-in-ci.md) で見送った「ステータスの値の書き方を揃えること」を、この ADR で行う。旧形式のままでも読めるが、手で書いた行が新形式と旧形式で混ざらないようにする。
- 別々のブランチで同じ番号の ADR を作ると、後からマージしたほうの CI が失敗する。マージの前に番号を付けなおす手間が増えるが、同じ番号の ADR が master に並ぶことはなくなる。
- 手元の adr-guard (mise の `latest`) と CI (0.13.1 に固定) の版がずれることがある。adr-guard が上がったら、CI の版も上げる。

## 参考文献

- [tett23/adr-guard v0.13.1 のリリース](https://github.com/tett23/adr-guard/releases/tag/v0.13.1)
- [tett23/adr-guard v0.13.0 のリリース](https://github.com/tett23/adr-guard/releases/tag/v0.13.0)
- [tett23/adr-guard ADR 0018: 重複したADRの番号を検出し、番号を振りなおして修復できるようにする](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0018-repair-duplicate-adr-numbers.md)
- [tett23/adr-guard ADR 0019: モジュールの名前やディレクトリを前に付けたADRの参照を、そのディレクトリのADRへつなぐ](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0019-module-qualified-adr-references.md)
- [tett23/adr-guard ADR 0020: シンボリックリンクの文書を、ADRの参照の検査と書きかえの対象から除く](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0020-skip-symlinked-documents.md)
- [tett23/adr-guard ADR 0021: Codex の PreToolUse hook で、コミット済みのADRと記録の編集を拒否する](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0021-codex-hook.md)
- [tett23/adr-guard ADR 0022: 状態と遷移を別々の代数的データ型で表す](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0022-status-transitions.md)
- [tett23/adr-guard ADR 0023: trace で元の決定から修正ADRをたどる](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0023-trace-amendments.md)
- [tett23/adr-guard ADR 0024: 移行スクリプトに --dry-run を設け、失敗を最後まで数える](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0024-migration-dry-run-and-error-count.md)
- [tett23/adr-guard ADR 0025: 新形式のステータス行に、実装待ちの修正、補足、注記、別のリポジトリの修正先を加える](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0025-extend-canonical-status-amendments.md)
- [tett23/adr-guard ADR 0026: 旧形式のステータス行の修正先を、リンク先と裸の番号からも読む](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0026-read-more-legacy-references.md)
- [tett23/adr-guard ADR 0027: 旧形式の `置換（…）` を、修正を受けた状態として読む](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0027-read-legacy-replaced-status.md)
- [tett23/adr-guard ADR 0028: 旧形式の部分名から修飾子と区切りの記号を除き、決められない部分名を移行しない](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0028-fix-legacy-part-names.md)
