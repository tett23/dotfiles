# ADR 0126: セキュリティを監査する security-audit スキルと、ADR 違反と予算違反を監査する conformance-audit スキルを足す

Status: accepted

## 文脈

本人から、監査のスキルを作るよう頼まれた。決まったことは次のとおりである。

- 監査は、いちばん上のモデルで行う。推論の強さ (effort) はモデルの既定にし、変えたいときは本人がプロンプトで指示する。
- 監査するのは、セキュリティ、ADR 違反、予算違反の三つである。予算違反とは、決められた性能を満たせないことである。
- 予算は、ADR (受けいれ条件) と、リポジトリの予算の一覧の両方に書く。二つが食い違うときは、ADR を正とする。
- スキルは、セキュリティの監査と、それ以外 (ADR 違反と予算違反) の監査とに分ける。

[ADR 0111](0111-claude-agents-in-dotfiles.md) と [ADR 0117](0117-codex-model-roles.md) は、モデルを固定した `auditor` のエージェント (役割) を、Claude Code と Codex に置いた。
`auditor` の説明は「ADR と実装・テストの乖離の調査と、セキュリティ監査を行う」で、監査の手順と記録の形は決めていない。

新しいスキルを dotfiles で管理することと [ADR 0118](0118-split-instructions-into-skills.md) の関係は、[ADR 0123](0123-context-restore-skill.md) の「文脈」と同じである ([ADR 0118](0118-split-instructions-into-skills.md) の「実装しないこと」は、新しく作るスキルを指さない)。

この ADR は、[ADR 0124](0124-invariant-and-test-naming.md) (提案) の番号の決まりを前提にする。
[ADR 0124](0124-invariant-and-test-naming.md) を採択しないときは、この ADR の「番号」を「不変条件と受けいれ条件の節の中の項目」に読み替える。

## 調査した事項

- Claude Code の `auditor` (`.claude/agents/auditor.md`) は、`model: fable`、`tools: Read, Grep, Glob, Bash` で、推論の強さを指定していない。本文は「コードを変えず、読んで動かして確かめるだけにする」である。
- Codex の `auditor` (`codex/agents/auditor.toml`) は、`model = "gpt-6-astra"`、`model_reasoning_effort = "xhigh"` である ([ADR 0117](0117-codex-model-roles.md) の「実装すること」の表)。
- Codex の役割のファイルは、`name`、`description`、`nickname_candidates` のほかのキーで、`config.toml` の値を上書きする ([ADR 0117](0117-codex-model-roles.md) の「調査した事項」)。
  今の `~/.codex/config.toml` は `model_reasoning_effort = "low"` である。役割のファイルからこのキーを消したときに、`config.toml` の値を継ぐかは、Codex のソースで確かめていない。
- Codex のモデルの一覧 (`~/.codex/models_cache.json`) の `gpt-6-astra` の `default_reasoning_level` は `"medium"` である。
- `docs/specifications.md` の 277 行は、Codex の `auditor` を「`gpt-6-astra`、推論 `xhigh`」と書く。
- 共通の指示の「docs/specifications.mdとREADME.md」の節 (`.claude/CLAUDE.md` と `codex/AGENTS.md`) は、監査と性能の計測の記録を `docs/` の下に置き、`docs/audit/`、`docs/audits/`、`docs/benchmark/`、`docs/benchmarks/` の記録をコミットした後に変えないとしている。
- dotfiles は、監査の記録を `docs/audit/` (単数形) に置いている。2026-10-07 から 2026-11-04 までの 9 件の記録がコミットされている (`git ls-files docs/audit`)。`docs/audits/` は無い。
- Golem (`tett23/golem`) は、監査の記録を `docs/audits/` に `2026-10-17-security-audit.md` のような名前で、性能の計測の記録を `docs/benchmarks/` に置いている。
- Claude Code の `auditor` の前付けに推論の強さの指定が無いとき、モデルの既定で動くのか、呼び出したセッションの推論の強さを継ぐのかは、確かめていない。
- `adr` スキルによれば、変更の要素の `kind` は `"replace"` (置換。省いたときの値)、`"supplement"` (補足)、`"note"` (注記) のどれかである。
- 同じく `adr` スキルによれば、`accepted-pending` と `superseded-pending` は実装を待つ状態で、`superseded [...]` は後の ADR が変更を記録した状態である。変更の要素の `part` が `null` なら ADR 全体を、文字列なら一部を指す。

## 実装すること

### 二つのスキルに共通の決まり

二つのスキルは、それぞれ一つのファイルで読めるように、次の共通の決まりを両方に書く。

- 使う場面: 本人がその監査を頼んだとき。リリースの前など、決まった時期の監査を頼まれたときも含む。本人が「監査」とだけ頼んだときは、二つとも行う。`conformance-audit` は、予算を決める前と変える前にも読む (予算の一覧の書き方を持つため)。
- 実行のしかた: 監査は `auditor` に任せる。Claude Code の `auditor` は Fable、Codex の `auditor` は `gpt-6-astra` で、推論の強さはモデルの既定である。本人がプロンプトで推論の強さを指示したときだけ、それに従う。`auditor` はコードもファイルも変えず、読んで動かして確かめる。
- 監査の範囲と基準の版: 読むコミット (`git rev-parse HEAD`) と、範囲 (リポジトリ全体か、ある版からの差分か) を、監査の初めに決める。
- 指摘の形: 観点、重大度 (高、中、低)、根拠 (`file:line`、動かしたコマンドと出力の要る部分、ADR の該当箇所と番号)、何が問題か。確かめられなかったことは「未確認」として分ける。
- 記録: 対象のリポジトリに `docs/audits/` があるとき、または本人が記録を求めたときに、監査の結果を `docs/audits/<YYYY-MM-DD>-security-audit.md` か `docs/audits/<YYYY-MM-DD>-conformance-audit.md` に書く。ディレクトリが無いときは作る。置き場所は、標準の docs の構成 ([ADR 0129](0129-standard-docs-layout.md)、提案) に従う。
  - 記録を書くのはメインのモデルである。メインのモデルは、頭に日付、読んだコミット、範囲、使ったモデル、指定した推論の強さ (指定が無ければ「指定なし」) と、`auditor` に報告させた推論の強さを書き、その後に `auditor` が返した指摘を変えずに貼る。指摘を要約し直したり、言い換えたりしない。
  - 記録はコミットした後に変えない。直したことや追加の監査は、新しい記録に書く。
  - 記録を書かないときは、同じ形で本人にチャットで返す。
- 直すこと: 監査は報告までで止める。直すのは、本人が求めたときである。仕様や振る舞いを変える直しは、ADR を作ってから行う。

### security-audit スキル

`agents/skills/security-audit/SKILL.md` を作り、上の共通の決まりと、次の観点を書く。

- 秘密の情報の混入 (リポジトリ、履歴、ログ、設定)。
- 外から来る入力の扱い (コマンドやパスへの埋め込み、検証の欠け)。
- 権限 (ファイルの権限、hook やエージェントに許すツール、sandbox の外での実行)。
- 依存の取り込みと固定 (取得元、版の固定、ハッシュ)。

### conformance-audit スキル

`agents/skills/conformance-audit/SKILL.md` を作り、上の共通の決まりと、次の二つの観点を書く。

- ADR 違反: 対象は、`accepted` の ADR と、`superseded [...]` の ADR のうち `kind` が `replace` の変更を受けていない部分である (`supplement` と `note` は元の部分を置き換えない)。
  - その「実装すること」と「実装しないこと」が実装に表れているか。
  - 不変条件と、自動で確かめる受けいれ条件は、番号ごとに、その番号を名前に持つテストがあり、通るか。テストの名前が [ADR 0124](0124-invariant-and-test-naming.md) の形に合っているか。
  - 手で確かめる受けいれ条件は、テスト設計に、番号の付いた確かめの手順があるか。
  - 仕様書と README が ADR と合っているか。
  - `accepted-pending` と `superseded-pending` の ADR は違反に数えず、「未実装」の一覧として別に返す。
- 予算違反: 予算の一覧と ADR の受けいれ条件の予算を集め、計測の記録 (`docs/benchmarks/` など) か、リポジトリの計測の手順で得た値と比べる。計測できなかった予算は「未確認」とする。予算の一覧も ADR の予算も無いときは、この観点に「予算なし」と返す。

### 予算の一覧

`conformance-audit` スキルに、予算の一覧の書き方を書く。

- 置き場所は `docs/budgets.md` とする。モノレポでモジュールごとに持つときは `docs/<module name>/budgets.md` とする。
- 予算の一覧は、見出しの行が `| 名前 | 指標と単位 | 比較 | 値 | 計測のコマンド | ADR |` の表とし、予算ごとに一行を書く。「ADR」の列には、決めた ADR と番号 (`ADR NNNN A1` など) を書く。
  - 「比較」は `<=` (値が上限) か `>=` (値が下限) とする。
  - 「計測のコマンド」は、リポジトリのルートで動かすと、計測した値を一つの数として標準出力の最後の行に出すコマンドを、インラインのコードで書く。
  - この形は、CI で予算違反を見つけるスクリプト ([ADR 0128](0128-budget-check-in-ci.md)) が読む。
- 予算を決めるのは ADR である。ADR の受けいれ条件に予算を書いたら、同じ変更で予算の一覧にも書く。予算の一覧だけを変えてはいけない。
- 正とする ADR は、`superseded [...]` をたどった最新の ADR である。予算の一覧と ADR が食い違うときは、監査でその食い違いも指摘にし、直すときは予算の一覧を ADR に合わせる。

### エージェントと共通の指示

- `codex/agents/auditor.toml` の `model_reasoning_effort` を `"xhigh"` から `"medium"` (`gpt-6-astra` の既定) にする。キーを消すと `config.toml` の `"low"` を継ぐおそれがあるので、モデルの既定の値を書く。
  採択の後のコミットで、[ADR 0117](0117-codex-model-roles.md) のステータスを `superseded [{"part":"実装すること (auditor の推論の強さ)","by":["docs/adr/0126-audit-skill.md"]},{"part":"トレードオフ (auditor の推論の強さ)","by":["docs/adr/0126-audit-skill.md"]}]` にする。
- `.claude/agents/auditor.md` と `codex/agents/auditor.toml` の説明 (`description`) に、「セキュリティの監査を頼まれたときは `security-audit` スキルの、ADR 違反と予算違反の監査を頼まれたときは `conformance-audit` スキルの手順で行う」を足す。
- `flake.nix` の `home.file` で、`agents/skills/security-audit` と `agents/skills/conformance-audit` を、それぞれ `~/.claude/skills/` と `~/.agents/skills/` の同じ名前にリンクする ([ADR 0118](0118-split-instructions-into-skills.md) と同じ形)。
- 共通の指示 (`.claude/CLAUDE.md`、`codex/AGENTS.md`) の「スキル」の表に、二つの行を足す。
  - `security-audit`: 使うときは「セキュリティの監査を頼まれたとき。本人が「監査」とだけ頼んだとき」、使いかたは「`auditor` に任せ、指摘を変えずに記録するか返す」。
  - `conformance-audit`: 使うときは「ADR 違反と予算違反の監査を頼まれたとき。本人が「監査」とだけ頼んだとき。予算を決める前、変える前」、使いかたは「`auditor` に任せ、指摘を変えずに記録するか返す。予算は ADR と予算の一覧の両方に書く」。
  [ADR 0125](0125-roadmap-skill.md) の行があれば、その後に置く。
- `docs/specifications.md` のリンクの表に `security-audit` と `conformance-audit` を足し、277 行の Codex の `auditor` の「推論 `xhigh`」を「推論 `medium` (モデルの既定)」に直す。Claude Code の節に、監査のスキルと予算の一覧を書く。README は変えない。

## 実装しないこと

- 監査を CI や決まった時刻に自動で動かすこと。
- dotfiles に `docs/budgets.md` を作ること。
- Claude Code の `auditor` に推論の強さを書くこと。今は指定していない。指定の無いときの動き (モデルの既定か、呼び出したセッションの値か) は確かめていないので、A4 の試しの監査で、`auditor` に、自分がどの推論の強さで動いているかを報告させ、その答えを記録の頭に添える。

## 不変条件

なし。監査の手順と記録の形、エージェントの設定だけを決める ADR で、入力に対する振る舞いを決めない。

## 受けいれ条件

- A1: `agents/skills/security-audit/SKILL.md` と `agents/skills/conformance-audit/SKILL.md` に、「実装すること」のそれぞれの決まりと、共通の決まりがすべて書いてある。
- A2: `codex/agents/auditor.toml` の `model_reasoning_effort` が `"medium"` で、Claude Code と Codex の `auditor` の説明が二つのスキルを指す。
- A3: Claude Code と Codex の新しいセッションで、スキルの一覧に `security-audit` と `conformance-audit` が出る。
- A4: dotfiles で試しに二つの監査を頼むと、`auditor` がそれぞれの観点で指摘を返し、`docs/audits/` に二つの記録ができる (dotfiles の `docs/audit/` は、[ADR 0129](0129-standard-docs-layout.md) で `docs/audits/` に移す)。記録の形 (日付、読んだコミット、範囲、使ったモデル、指定した推論の強さと auditor が報告した推論の強さ、観点、重大度、根拠、未確認、未実装の一覧) がそろっている。dotfiles には予算が無いので、予算違反の観点は「予算なし」と返る。
- A5: 共通の指示の両方のファイルの「スキル」の表に、`security-audit` と `conformance-audit` の行が同じ文であり、`docs/specifications.md` のリンクの表と 277 行の直しが入っている。

## テスト設計

設定と手順の変更なので、CI の自動のテストは書かない。

- A1: 実装の後に、スキルを「実装すること」の各項目と突き合わせ、`close-reading` で精読する。
- A2: `grep -n model_reasoning_effort codex/agents/auditor.toml` が `"medium"` の 1 行を返す。2 つの `auditor` の説明を読む。
- A3: 本人が `sudo darwin-rebuild switch --flake ~/dotfiles#dione` を実行した後に、リンクと、Claude Code と `codex exec` のスキルの一覧を確かめる。
- A4: switch の後に、dotfiles の二つの監査を `auditor` に頼み、返った指摘の形と、`docs/audits/` にできた二つの記録の形を確かめる。記録は、ほかの記録と同じく、コミットした後に変えない。
- A5: 両ファイルの「スキル」の節を切り出して `diff` し、差分が無いことを確かめる。`grep -n 'security-audit\|conformance-audit\|xhigh' docs/specifications.md` で仕様書の直しを確かめる。

## トレードオフ

- いちばん上のモデルで監査するので、トークンと時間を多く使う。監査は、頼まれたときだけ行う。
- Codex の `auditor` に `"medium"` を書くので、`gpt-6-astra` の既定が変わっても追わない。モデルを変えるときに、推論の強さも見直す。
- 予算を ADR と一覧の両方に書くので、同じ値が二か所にある。食い違いは監査で見つけ、一覧を ADR に合わせる。
- 共通の決まりを二つのスキルに書くので、変えるときは両方を同じく変える。それぞれのスキルを一つのファイルで読めることを優先する。
- ADR 違反の観点は、[ADR 0124](0124-invariant-and-test-naming.md) の番号の付いたテストを手がかりにする。番号を付ける前の ADR とテストは、内容を読んで確かめることになる。

## 参考文献

- dotfiles の `.claude/agents/auditor.md`、`codex/agents/auditor.toml`、`.claude/CLAUDE.md`、`agents/skills/adr/SKILL.md`、[ADR 0111](0111-claude-agents-in-dotfiles.md)、[ADR 0117](0117-codex-model-roles.md)、[ADR 0118](0118-split-instructions-into-skills.md)、[ADR 0123](0123-context-restore-skill.md)、[ADR 0124](0124-invariant-and-test-naming.md)、[ADR 0125](0125-roadmap-skill.md)
- `~/.codex/models_cache.json`、`~/.codex/config.toml`
- Golem (`tett23/golem`) の `docs/audits/`、`docs/benchmarks/`
