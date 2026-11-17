# ADR 0129: docs/ の標準のディレクトリとファイルの構成を決める

Status: superseded [{"part":"実装すること (標準の構成: 表のパスの中だけの変更でビルドとテストを省く決まり)","by":["docs/adr/0138-docs-layout-ci-rule-wording.md"]},{"part":"実装すること (標準の構成: 「GitHub actions」の節の改め方)","by":["docs/adr/0138-docs-layout-ci-rule-wording.md"]},{"part":"受けいれ条件 (A1)","by":[],"kind":"note","note":"一字も違わずには両ファイルの節どうしの一致と読み、ADR の文との一致とは読まない"}]

## 文脈

本人から、全リポジトリの `docs/` の標準のディレクトリとファイルの構成を決めるよう頼まれた。本人が挙げた構成は次のとおりである。

- `adr/`: ADR。不変。
- `specifications.md`: 仕様。中身が ADR と食い違うときは ADR が正。ADR から作り直せる。可変。
- `roadmap.md`: ロードマップ。可変。
- `audits/`: 監査の記録。不変。
- `benchmarks/`: ベンチマークの記録。不変。
- `glossary.md`: 用語集。可変。
- `research/`: 調査をまとめる。可変。
- どれも、`docs/` の中だけの変更では、文書のほかの CI は要らない。
- モノレポでは、モジュールの名前のディレクトリを切り、同じファイルを置ける。置かなくてもよい。ただし `adr/` は必ず置き、セットアップのときに `.gitkeep` を置く。

加えて、本人は、予算の一覧 `budgets.md` も標準の構成に足すこと ([ADR 0126](0126-audit-skill.md)、提案) と、dotfiles の単数形の `docs/audit/` を、adr-guard の許可のトレーラーを付けて `docs/audits/` に移すことを決めた。

## 調査した事項

- dotfiles の `docs/` は、`adr/`、`audit/`、`specifications.md` だけを持つ (`ls docs`)。`docs/audit/` には、2026-10-07 から 2026-11-04 までの 9 件の記録がある (`git ls-files docs/audit`)。
- Golem (`tett23/golem`) の `docs/` は、`adr/`、`audits/`、`benchmarks/`、`glossary.md`、`roadmap.md` のほかに、`ci-timings/`、`compatibility.md`、`diagnostics.md`、`heap-measurement.md` などのファイルと、モジュールの名前のディレクトリ (`golem-pdf/` など) を持つ (`ls docs`)。
- adr-guard は、`docs/audit/`、`docs/audits/`、`docs/benchmarks/`、`docs/benchmark/` の下のすべてのファイルを記録として扱い、コミットした後の変更を止める。`--allow-links` は記録には効かない (`adr-guard --help`)。
- 共通の指示の「docs/specifications.mdとREADME.md」の節は、次の 4 つの段落を持つ。仕様と README を ADR と同時に直す。監査と性能の計測の記録を `docs/` に置き、コミットした後に変えない。記録の 4 つのディレクトリを変えない。仕様書から ADR を示すときはリンクを付ける。
- 共通の指示の「GitHub actions」の節は、ドキュメント類だけの更新ではビルドとテストを省き、文書の検査と ADR と記録の変更不可の検査は省かないとしている。同じ節は、「拡張子や `docs/` 配下であることだけで、省略してよいと判断しない」とし、ビルドやテストの入力になるファイルの変更では省かないとしている。
- `docs/budgets.md` は、[ADR 0128](0128-budget-check-in-ci.md) (提案) の `bin/budget-check` の入力になる。
- dotfiles のコミット済みの ADR のうち 18 ([ADR 0009](0009-fix-git-tmux-nvim-audit.md)、[0010](0010-fix-zsh-fzf-audit.md)、[0014](0014-fix-remaining-audit-items.md)、[0015](0015-fix-breaking-audit-items.md)、[0021](0021-modernize-send-to-kindle.md)、[0023](0023-fix-remaining-audit-items-2.md)、[0024](0024-orch-models-and-headless-install.md)、[0027](0027-file-layout-without-behavior-change.md)、[0041](0041-file-layout-cleanup-2.md)、[0042](0042-xdg-config-locations.md)、[0043](0043-remove-vimbackup-and-zshrc-mine.md)、[0045](0045-fix-audit-failures-and-risks.md)、[0046](0046-fix-audit-non-breaking.md)、[0055](0055-improvements-2026-10-13.md)、[0057](0057-remaining-improvements-2.md)、[0058](0058-git-fsck-and-vscode-cleanup.md)、[0059](0059-bat-map-syntax-and-nvim-options.md)、[0079](0079-fix-command-audit-2026-11-04.md)) が、`docs/audit/` の記録のファイルを 21 か所で引く (`rg --count-matches 'audit/20' docs/adr --glob '!012*'`。この ADR と、0120 番台の提案の ADR を除くため)。そのうち Markdown のリンク (`](../audit/20…`) は 5 か所 ([ADR 0055](0055-improvements-2026-10-13.md)、[0057](0057-remaining-improvements-2.md)、[0058](0058-git-fsck-and-vscode-cleanup.md)、[0059](0059-bat-map-syntax-and-nvim-options.md)、[0079](0079-fix-command-audit-2026-11-04.md)) で、残る 16 か所は本文かインラインのコードのパスである。
  [ADR 0032](0032-adr-guard.md) と 0066 は、記録のファイルではなく、adr-guard が検査するディレクトリの一覧として `docs/audit/` を挙げる。
  記録のうち 3 件も `docs/audit/` を引く。`.claude/CLAUDE.md`、`codex/AGENTS.md`、`docs/specifications.md`、`agents/skills/close-reading/SKILL.md` も `docs/audit/` に触れる (`rg -l 'docs/audit/'`)。
- Claude Code の hook (`adr-guard claude-hook --allow-status`) は、コミット済みの ADR を Edit で変えることを、リンクの直しも含めて止める。
- `adr-guard links --fix` が直すのは、リンクの無い ADR の参照だけで、記録へのリンクやパスは直さない (`adr-guard --help`)。
- adr-guard は、意図して ADR や記録を書き換えるとき、その書き換えだけの一つのコミットにし、pre-commit hook は `ADR_GUARD_ALLOW=<理由>`、CI はコミットのメッセージのトレーラー `ADR-Guard-Allow: <理由>` で許す (`docs/specifications.md` の adr-guard の節)。

## 実装すること

### 標準の構成

共通の指示 (`.claude/CLAUDE.md`、`codex/AGENTS.md`) の「docs/specifications.mdとREADME.md」の節を「docs/ の構成」に改め、次の表と決まりを書く。今の節の 4 つの段落は、次のように扱う。仕様と README を同時に直す段落と、仕様書から ADR を示すときにリンクを付ける段落は、そのまま残す。監査と性能の計測の記録を「適切なディレクトリを切って」置く段落は、表の `docs/audits/` と `docs/benchmarks/` に置くことに改める。記録の 4 つのディレクトリを変えない段落は、下の決まりに含める。

| パス | 中身 | 変えてよいか | 置くか |
| --- | --- | --- | --- |
| `docs/adr/` | ADR | コミットした後はステータスの行とリンクのほかを変えない | 必ず置く |
| `docs/specifications.md` | 仕様。今の振る舞いを書く。ADR と食い違うときは ADR が正。ADR から作り直せるように書く | 変えてよい | 仕様があれば置く |
| `docs/roadmap.md` | ロードマップ。まだ無いものを書く | 変えてよい | あれば置く |
| `docs/budgets.md` | 予算の一覧。ADR と食い違うときは ADR が正 | 変えてよい (ADR と同じ変更で) | 予算があれば置く |
| `docs/glossary.md` | 用語集 | 変えてよい | あれば置く |
| `docs/research/` | 調査のまとめ | 変えてよい | あれば置く |
| `docs/audits/` | 監査の記録 | コミットした後は変えない、消さない、移さない | 記録があれば置く |
| `docs/benchmarks/` | ベンチマークの記録 | コミットした後は変えない、消さない、移さない | 記録があれば置く |

- 表のほかのファイルやディレクトリを `docs/` に置いてもよい。表と同じ中身のものは、表のパスに置く。
- モノレポでは、`docs/<module name>/` に、表と同じ構成を置ける。`docs/<module name>/adr/` は必ず置き、ほかは置かなくてもよい。リポジトリのルートの `docs/` には、モジュールに属さないものを置く。
- 表のパスの中だけの変更では、ビルドとテストを省く。ただし、`docs/budgets.md` の変更では、予算の確かめ ([ADR 0128](0128-budget-check-in-ci.md) の `bin/budget-check`) を省かない。予算の確かめを CI のどのイベントで動かすかは、[ADR 0128](0128-budget-check-in-ci.md) のとおり、各リポジトリの ADR で決める。文書の検査と、ADR と記録の変更不可の検査は省かない。
  共通の指示の「GitHub actions」の節の「拡張子や `docs/` 配下であることだけで、省略してよいと判断しない」を、「標準の構成の `docs/` のパス (`docs/budgets.md` を除く) の中だけの変更では省く。ほかの `docs/` のファイルは、ビルドやテストの入力になるかで判断する」に改める (本人の決定)。
- 記録の変更不可の決まりは、標準の `docs/audits/` と `docs/benchmarks/` に加えて、adr-guard が記録として扱う単数形の `docs/audit/` と `docs/benchmark/` にも当てはめる。新しい記録は、標準の複数形のディレクトリに書く。

### セットアップ

- `adr` スキルの adr-guard の入れ方の手順に、「`docs/adr/.gitkeep` を置く。モノレポでは、各モジュールの `docs/<module name>/adr/.gitkeep` も置く」を足す。

### dotfiles の docs/audit/ を docs/audits/ に移す

- `git mv docs/audit docs/audits` で 9 件の記録を移す。中身は変えない。
- 同じコミットで、上の 18 の ADR の中の、記録のファイルを引く 21 か所 (リンクの 5 か所と、本文とインラインのコードのパスの 16 か所) を、`docs/audits/` を指すように直す。`audit/20` を `audits/20` に置き換えるだけで、ほかは変えない。
  Claude Code の hook が Edit を止めるので、シェルの `sed` で直す。[ADR 0032](0032-adr-guard.md) と 0066 のディレクトリの一覧と、記録の中の `docs/audit/` は変えない (記録は中身を変えない)。
- このコミットは、記録の移動とリンクの直しだけを含み、pre-commit hook は `ADR_GUARD_ALLOW=<理由>`、コミットのメッセージはトレーラー `ADR-Guard-Allow: <理由>` を持つ。理由には `dotfiles ADR 0129` と書く。
- 別のコミットで、`docs/specifications.md`、`codex/AGENTS.md`、`.claude/CLAUDE.md`、`agents/skills/close-reading/SKILL.md` の `docs/audit/` の記述を見直し、記録の置き場所を指すものを `docs/audits/` に直す。adr-guard が検査するディレクトリの一覧として挙げているものは、そのまま残す。
- `docs/specifications.md` の Claude Code の節の、共通の指示の中身を述べる記述に、「docs/ の標準の構成」を一項として足す。

### ほかの ADR との関係

- [ADR 0125](0125-roadmap-skill.md) (roadmap)、[ADR 0126](0126-audit-skill.md) (監査と予算の一覧)、[ADR 0128](0128-budget-check-in-ci.md) (CI の予算の確かめ) は、この表のパスを使う。

## 実装しないこと

- ほかのリポジトリ (Golem など) の `docs/` を、dotfiles の作業の中で組み直すこと。それぞれのリポジトリの ADR で行う。
- 表のほかの `docs/` のファイル (Golem の `compatibility.md` など) を、表のパスに移すこと。
- adr-guard が記録として扱うディレクトリの一覧を変えること。

## 不変条件

なし。ディレクトリとファイルの置き場所の決まりと、移す手順だけを決める ADR で、入力に対する振る舞いを決めない。

## 受けいれ条件

- A1: 共通の指示の両方のファイルに「docs/ の構成」の節があり、表と決まりが一字も違わずに書いてある。
- A2: `adr` スキルの adr-guard の入れ方の手順に、`.gitkeep` を置く手順がある。
- A3: dotfiles の `docs/audit/` が無く、9 件の記録が `docs/audits/` に中身を変えずにあり、コミット済みの ADR のリンクが `docs/audits/` を指している。その移動のコミットは、トレーラー `ADR-Guard-Allow` を持ち、記録の移動とリンクの直しだけを含む。
- A4: CI の `adr` ジョブと、`adr-guard links` が通る。

## テスト設計

文書と置き場所の変更なので、CI の自動のテストは書かない。

- A1: 両ファイルから「docs/ の構成」の節を切り出して `diff` し、差分が無いことを確かめる。`close-reading` で精読する。
- A2: `adr` スキルを読み、精読する。
- A3: 移動のコミットについて、`git show -M --name-status` が記録の 9 件の `R100` の行と、変えた ADR の `M` の行だけを示し、`git log -1 --format=%B` にトレーラーがあることを確かめる。`rg --count-matches 'audits/20' docs/adr --glob '!012*'` が 21 か所を返し、`rg 'docs/audit/20|\.\./audit/20' docs/adr --glob '!012*'` が 0 件になる。
- A4: push した後の CI と、手元の `adr-guard links` が通ることを確かめる。

## トレードオフ

- 単数形の `docs/audit/` を移すので、記録を移さない決まりの例外を一度だけ作る。トレーラーとコミットで、例外の理由を残す。
- 表のほかのファイルを許すので、リポジトリごとに `docs/` の中身は揃いきらない。表にあるものだけを揃える。
- `docs/specifications.md` を「ADR から作り直せるように書く」とするが、作り直す道具は作らない。仕様書の各記述が ADR へのリンクを持つことで、作り直せるようにする。

## 参考文献

- `adr-guard --help`
- dotfiles の `docs/`、`.claude/CLAUDE.md`、`docs/specifications.md`、[ADR 0125](0125-roadmap-skill.md)、[ADR 0126](0126-audit-skill.md)、[ADR 0128](0128-budget-check-in-ci.md)
- Golem (`tett23/golem`) の `docs/`
