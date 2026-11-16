# ADR 0127: 共通の指示に、スキルを使うときと使いかたの表を置く

Status: proposed

## 文脈

本人から、各スキルの使いかたと使うタイミングを、共通の指示 (`.claude/CLAUDE.md`、`codex/AGENTS.md`) に書くよう頼まれた。

今の共通の指示は、スキルごとに「…前に、`<スキル>` スキルを読む」の一文を、話題の節に一つずつ置いている ([ADR 0118](0118-split-instructions-into-skills.md)、[ADR 0122](0122-move-adr-rules-into-skill.md)、[ADR 0123](0123-context-restore-skill.md))。
`docs/specifications.md` の Claude Code の節は、「共通の指示には、いつも守る決まりと、使う前にスキルを読むことだけを書く」としている (「調査した事項」)。
使いかたの要点を共通の指示に書くことは、この一文の範囲を超えるので、この ADR で決め直す。

## 調査した事項

- コミット `9744344` の `.claude/CLAUDE.md` で、`grep -n 'スキルを読\|スキルで精読\|スキルの手順で'` は次の 6 行を返す。
  - 13 行 (「ADR」の節): `adr` スキルを読む一文 ([ADR 0122](0122-move-adr-rules-into-skill.md))。
  - 32 行 (「文書の書き方」の節): `doc-writing` スキルを読む一文 ([ADR 0118](0118-split-instructions-into-skills.md))。
  - 33 行 (同じ節): 文書を変えたら `close-reading` スキルで精読する一文 ([ADR 0123](0123-context-restore-skill.md))。
  - 42 行 (「タグとリリース」の節): `release` スキルを読む一文で、この節の中身はこれだけである ([ADR 0118](0118-split-instructions-into-skills.md))。
  - 60 行 (「ai-chat-log」の節): `context-restore` スキルを読む一文 ([ADR 0123](0123-context-restore-skill.md))。
  - 99 行 (「任せるときの決まり」): `context-restore` スキルの手順で `chat-log` から取得する一文。
- `docs/specifications.md` の Claude Code の節は、次の二か所で共通の指示に書くものを決めている。
  - 「共通の指示には、いつも守る決まりと、使う前にスキルを読むことだけを書く」。この一文は [ADR 0118](0118-split-instructions-into-skills.md) を引いており、[ADR 0123](0123-context-restore-skill.md) で改めた形である。
  - 「共通の指示には、実装の前に ADR を作ること、…、`adr` スキルを読むこと、チャットでの ADR の表記だけを残す」([ADR 0122](0122-move-adr-rules-into-skill.md))。
- 「ADR」の節の一文は、`adr` スキルの説明 (`description`) にある「未実装の ADR をまとめて実装するとき」を挙げていない。
- `.claude/CLAUDE.md` と `codex/AGENTS.md` の違いは、[ADR 0114](0114-codex-agents-md.md) と [ADR 0117](0117-codex-model-roles.md) で決めたところ (出力の言語の主語、hook の設定の場所、`/goal`、Python の一行、モデルと役割の名前) だけである (`docs/specifications.md` の Codex の記述)。
- 提案中の [ADR 0125](0125-roadmap-skill.md) と [ADR 0126](0126-audit-skill.md) は、新しく作るスキルを、この ADR の表に行として足す。

## 実装すること

- 共通の指示の「原則」の次に、「スキル」の節を置く。
  - 節の頭に、「全リポジトリで使うスキルと、使うときと使いかたは次のとおりである。使うときが来たら、作業の前にそのスキルを読み、その手順に従う。」と書く。
  - 表の列は「スキル」「使うとき」「使いかた」とする。「使うとき」は、スキルの説明 (`description`) にある場面をすべて挙げる。「使いかた」は、そのスキルの手順のうち、作業の前に知っておく要点を一文か二文で書く。手順の全文はスキルに書く。
  - 行は、今ある `adr`、`doc-writing`、`close-reading`、`release`、`context-restore` の 5 つとする。
  - 表の後に、「スキルを足したり、使うときや使いかたを変えたりしたときは、この表も同じく変える (docs/adr/0127)。」と書く。
  - 表の行は、`.claude/CLAUDE.md` と `codex/AGENTS.md` で同じにする。モデルの名前を書かない。
- 表と重なる、スキルを読むだけの一文を消す。「ADR」の節の `adr` の一文、「文書の書き方」の節の `doc-writing` の一文、「ai-chat-log」の節の `context-restore` の一文、「タグとリリース」の節の `release` の一文である。一文だけだった「タグとリリース」の節は、見出しごと消す。
- いつも守る決まりの一文は残す。「文書を変えたら、本人に出す前に `close-reading` スキルで精読し、指摘を直す。」と、「任せるときの決まり」の `context-restore` の一文である。
- `docs/specifications.md` の Claude Code の節を、次の二か所で改める。
  - 「共通の指示には、いつも守る決まりと、使う前にスキルを読むことだけを書く」を、「共通の指示には、いつも守る決まりと、スキルの表 (使うときと使いかたの要点) だけを書く。手順の全文はスキルに書く」にする。
  - ADR の決まりの記述の「`adr` スキルを読むこと」を、「スキルの表の `adr` の行」にする。
- README は変えない。

## 実装しないこと

- スキルの本文を変えること。
- dotfiles のこのリポジトリのためだけのスキル (`.claude/skills/sync-deps/` など) を表に入れること。全リポジトリで使うスキルではない。

## 不変条件

なし。共通の指示の書き方だけを決める ADR で、入力に対する振る舞いを決めない。

## 受けいれ条件

- A1: `.claude/CLAUDE.md` と `codex/AGENTS.md` に「スキル」の節があり、5 つの行の「使うとき」が、それぞれのスキルの説明にある場面をすべて挙げている。
- A2: 両ファイルの「スキル」の節が、一字も違わない。
- A3: 「実装すること」で消すとした一文が両ファイルに無く、残すとした一文がある。
- A4: `docs/specifications.md` の Claude Code の節の二か所が、改めた文になっている。

## テスト設計

文書の変更なので、CI の自動のテストは書かない。

- A1: 表の各行と、`agents/skills/<名前>/SKILL.md` の説明を並べて読み、`close-reading` で精読する。
- A2: 両ファイルから「## スキル」の節を切り出して `diff` し、差分が無いことを確かめる。
- A3: 両ファイルで、消した 4 文に固有の句 (「`adr` スキルを読む (docs/adr/0122)」「`doc-writing` スキルを読む」「`release` スキルを読む」「`context-restore` スキルを読み、その手順で文脈を戻す」) を `grep -F` で探して 0 件であり、残した 2 文の句 (「スキルで精読し、指摘を直す」「スキルの手順で `chat-log` から取得する」) が 1 件ずつあることを確かめる。
- A4: `grep -n 'スキルの表' docs/specifications.md` で、改めた二か所を確かめる。

## トレードオフ

- 「使いかた」の要点を表とスキルの両方に書くので、スキルの手順を変えたときに、表が古いまま残ることがある。表の後の一文で、同じく変えることを求める。
- 表は、スキルが増えるほど長くなり、毎ターンの文脈に入る。行は一文か二文に抑える。

## 参考文献

- dotfiles の `.claude/CLAUDE.md`、`codex/AGENTS.md`、`agents/skills/*/SKILL.md`、`docs/specifications.md`、[ADR 0114](0114-codex-agents-md.md)、[ADR 0117](0117-codex-model-roles.md)、[ADR 0118](0118-split-instructions-into-skills.md)、[ADR 0122](0122-move-adr-rules-into-skill.md)、[ADR 0123](0123-context-restore-skill.md)、[ADR 0125](0125-roadmap-skill.md)、[ADR 0126](0126-audit-skill.md)
