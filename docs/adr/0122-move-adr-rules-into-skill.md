# ADR 0122: ADR の決まりを、全リポジトリ共通の指示から adr スキルに移す

Status: accepted

## 文脈

[ADR 0118](0118-split-instructions-into-skills.md) は、全リポジトリ共通の指示 (`.claude/CLAUDE.md` と `codex/AGENTS.md`) のうち、ときどきしか使わない節をスキルに分けた。
その「実装しないこと」で、「ADR」の節は必ず守らせたいので、スキルに移さず毎ターンの文脈に残すとした。

本人から、ADR についての記述は ADR を書くときにだけ要るので、スキルに移すよう頼まれた。この ADR は、[ADR 0118](0118-split-instructions-into-skills.md) の「実装しないこと」のその項目を変える。

## 調査した事項

- `.claude/CLAUDE.md` は 11826 バイトで、そのうち「ADR（docs/adr/）」の節 (見出しから「docs/specifications.mdとREADME.md」の前まで) は 77 行、4769 バイトある (`wc -c`)。`codex/AGENTS.md` の同じ節も 77 行である。
- 「ADR」の節には、次のものがある。
  - いつも守る決まり: 実装の前に ADR を作る。コミットした ADR はステータスの行を除いて変えない。作成時点ではレビューまでコミットしない。
  - ADR の状態を変えるときの決まり: 採択の記録のしかた、修正の ADR と `superseded`、破棄のしかた。
  - ADR を作る・書くときの決まり: adr-guard の入れ方の 3 つの手順、「ADRの構成」(置き場所とファイル名)、「ADRの中身」(テンプレート、不変条件の書き方)、`adr-guard links --fix`、`close-reading` での精読。
  - ADR を示すときの決まり: 「チャットでのADR表記」(3 行)。
  - 未実装の ADR を実装するときの決まり: 「未実装ADRの自動実装」(デフォルトの指示)。
- `.claude/CLAUDE.md` と `codex/AGENTS.md` の「ADR」の節の違いは、hook の文 (`~/.claude/settings.json` か `~/.codex/hooks.json` か) と、`/goal` の文 (Claude Code のコマンドか、頼まれたときか) の 2 か所だけである ([ADR 0114](0114-codex-agents-md.md)、[ADR 0115](0115-codex-adr-guard-hook.md))。
- adr-guard が機械で止めるものは、経路ごとに次のとおりである。
  - コミット済みの ADR の書き換え: Claude Code の hook (`adr-guard claude-hook`) と Codex の hook (`adr-guard codex-hook`) が編集の前に止め ([ADR 0115](0115-codex-adr-guard-hook.md))、pre-commit hook と CI もコミットで止める。
  - ステータスの行の形と状態の遷移 (初めてのコミットは `Status: proposed` であること): pre-commit hook と CI (`check-range`) が止める (`adr-guard --help` の「pre-commit と check-range は許可された状態遷移を検査する」、[ADR 0121](0121-adr-guard-0-13-in-ci.md))。編集の前の hook は止めない。
  - レビューの前に `Status: proposed` の ADR をコミットすることは、どの経路も止めない (正しい遷移なので通る)。
- Claude Code と Codex で共有するスキルは、dotfiles の `agents/skills/<名前>/` に置き、`~/.claude/skills/` と `~/.agents/skills/` にリンクしている ([ADR 0118](0118-split-instructions-into-skills.md))。

## 実装すること

- `agents/skills/adr/SKILL.md` を作り、「ADR」の節のうち、次を除いたものをすべて移す。
  - 共通の指示に残す、いつも守る決まりの 3 文 (下の項目)。
  - 「チャットでのADR表記」。ADR を書かないときにも、チャット、コミットログ、PR で使う。
- スキルの本文は、Claude Code と Codex の両方で読めるように、上の 2 か所の違いを次のように一つにする。見出しの深さと改行のほかは、ほかの文を一字も変えない。
  - hook の文: 「Claude Code と Codex の hook は全体の設定 (`~/.claude/settings.json`、`~/.codex/hooks.json`) で有効なので不要。」
  - `/goal` の文: 「`accepted-pending` の ADR を実装するとき (Claude Code では `/goal` で頼まれるとき) の、デフォルトの指示は以下。」
- スキルの `description` は、「ADR を書く・直す・採択する・実装する・破棄するとき、リポジトリに adr-guard を入れるとき、未実装の ADR をまとめて実装するとき」に使うと書き、「これらの前に必ず読む」と書く。
- `.claude/CLAUDE.md` と `codex/AGENTS.md` の「ADR」の節は、次の 3 つだけにする。
  - 「実装に入るまえに必ずADRを作成する。一度コミットしたADRはステータスの行を除き、変更不可。作成時点では `Status: proposed` で書き、人間のレビューを受けるまでコミットしない。」(今の 1 文目から 3 文目のまま)。
    3 文目は、機械で止まらない決まりなので残す。
  - 「ADR を書く・直す・採択する・実装する・破棄する前と、リポジトリに adr-guard を入れる前に、`adr` スキルを読む (docs/adr/0122)。」
  - 「チャットでのADR表記」の節 (今のまま)。
- `flake.nix` の `home.file` で、`agents/skills/adr` を `~/.claude/skills/adr` と `~/.agents/skills/adr` にリンクする。
- 次のスキルの、ADR の構成やテンプレートの参照先を、`adr` スキルに変える。
  - `agents/skills/close-reading/SKILL.md` の「ADR は全リポジトリ共通の指示の構成…と比べる」。
  - `agents/skills/doc-writing/SKILL.md` の「（ADR の節を参照）」。
- `docs/specifications.md` のリンクの表の「`doc-writing`・`release`・`close-reading`」に `adr` を足す。Claude Code の節のスキルの記述を、「ADR の決まりは共通の指示に残す」から、`adr` スキルに移したことに書きかえる。README は変えない。
- 採択の後のコミットで、[ADR 0118](0118-split-instructions-into-skills.md) のステータスを `superseded [{"part":"実装しないこと (「ADR」の節をスキルに移さない項目)","by":["docs/adr/0122-move-adr-rules-into-skill.md"]}]` にする。

## 実装しないこと

- 「チャットでのADR表記」をスキルに移すこと。
- adr-guard の hook や CI の検査を変えること。
- 「docs/specifications.mdとREADME.md」の節 (ADR で仕様を変えたら仕様書と README も変える、audit・benchmark の記録を変えない) をスキルに移すこと。ADR を書かない変更でも守る。

## 不変条件

なし。指示の文をファイルの間で移す手順と、リンクの設定だけを決める ADR で、入力に対する振る舞いを決めない。

## 受けいれ条件

- A1: `.claude/CLAUDE.md` と `codex/AGENTS.md` の「ADR」の節が、「実装すること」の 3 つだけになる。
- A2: 移す前の「ADR」の節の文が、「実装すること」の 2 か所の言いかえと、残した 3 文と「チャットでのADR表記」を除いて、`agents/skills/adr/SKILL.md` に一字も変わらずにある。
- A3: Claude Code と Codex の新しいセッションで、`adr` スキルが一覧に出て、ADR を書くよう頼むと、書く前に `adr` スキルを読む。

## テスト設計

設定の変更なので、CI の自動テストは書かない。実装の前と後に、次を確かめる。

- 実装の前の「ADR」の節を写しておき、`agents/skills/adr/SKILL.md` の本文 (前付けと見出しの深さを除く) と `diff` する。差分が、「実装すること」の 2 か所の言いかえ、見出しの深さと改行、移さなかったものだけになる。
- `wc -c .claude/CLAUDE.md codex/AGENTS.md` を、実装の前と後で比べる。
- `.claude/CLAUDE.md` と `codex/AGENTS.md` の差分が、[ADR 0114](0114-codex-agents-md.md)・[ADR 0117](0117-codex-model-roles.md) で決めたところから、「ADR」の節の 2 か所を除いたものになる。
- `nix flake check --no-build` が通る。
- 本人が `sudo darwin-rebuild switch --flake ~/dotfiles#dione` を実行した後:
  - `~/.claude/skills/adr` と `~/.agents/skills/adr` が、dotfiles の `agents/skills/adr` を指すリンクになる。
  - Claude Code の新しいセッションと `codex exec` で、使えるスキルの一覧に `adr` が出る。
  - それぞれで、使い捨てのリポジトリ (`git init` したスクラッチパッドのディレクトリ) に小さな ADR を書くよう頼み、ADR のファイルを書く前に `adr` スキルを読むことを、ツールの呼び出しの順で確かめる。書いた ADR が `Status: proposed` で、テンプレートの節の並びに合う。

## トレードオフ

- スキルの本文は、使うと判断されたときにしか読まれない。判断を誤ると、テンプレートや採択の記録のしかたを読まずに ADR を書くことがある。
  ただし、コミット済みの ADR の書き換えと、ステータスの行の形や状態の遷移の誤りは、adr-guard が機械で止める (「調査した事項」)。止まらないのは、節の並びや不変条件の書き方などの形の誤りと、レビューの前のコミットである。
  形の誤りは `close-reading` での精読 (スキルに移す決まりの一つ) と本人のレビューで見つける。レビューの前のコミットは、共通の指示に残す 3 文目で止める。
- 共通の指示の「ADR」の節に、いつも守る 3 文を残すので、ADR を作らずに実装に入ることは、今と同じく毎ターンの指示で止める。

## 参考文献

- dotfiles の `.claude/CLAUDE.md`、`codex/AGENTS.md`、[ADR 0114](0114-codex-agents-md.md)、[ADR 0115](0115-codex-adr-guard-hook.md)、[ADR 0117](0117-codex-model-roles.md)、[ADR 0118](0118-split-instructions-into-skills.md)、[ADR 0121](0121-adr-guard-0-13-in-ci.md)
