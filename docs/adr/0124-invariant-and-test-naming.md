# ADR 0124: ADR の不変条件と受けいれ条件の番号と、テストの名前の付け方をそろえる

Status: accepted

## 文脈

本人から、ADR の不変条件とテストの名前などの書き方を、全リポジトリでそろえるよう頼まれた。
`adr` スキル (`agents/skills/adr/SKILL.md`) は、振る舞いを決める ADR に「不変条件」の節を持たせ、不変条件に番号を付け、テストの名前にその番号を入れるとしている ([ADR 0122](0122-move-adr-rules-into-skill.md))。
しかし、番号の形と、テストの名前への入れ方は決めていない。
テンプレートの「受けいれ条件」の節にも、番号の決まりは無い。

番号と名前の形がそろうと、ADR の不変条件ごとにテストがあるかを、名前で機械的に探せる。
後で作る監査のスキル ([ADR 0126](0126-audit-skill.md)、提案) は、これを使って ADR 違反を探す。

本人は、テストの名前の頭に ADR と番号を置く形 (下の「実装すること」) にそろえ、今あるコミット済みの ADR とテストも、adr-guard の許可のトレーラーを付けて書き換えると決めた。

## 調査した事項

- `agents/skills/adr/SKILL.md` の 113 行は、不変条件について「一つずつ番号を付けて書き、境界の入力…の表を添える。テストの名前には、その番号を入れる」と書く。
  番号の形と、境界の入力の表の列は決めていない。
- テンプレートの節の並びは、「実装しないこと」「不変条件」「受けいれ条件」「テスト設計」の順である (`agents/skills/adr/SKILL.md` の 98〜104 行)。
- テストの名前を文字列で付ける仕組みがある。dotfiles の zsh のテスト (`zsh/tests/*.test.zsh` の `check "<名前>" …`) と、Golem の tasty の `testCase "<名前>"` である (`tett23/golem` の `modules/golem-eval/golem-eval.cabal` の 61 行が tasty に依存する)。
  tasty は `testGroup "<名前>" [...]` でテストを入れ子にし、Golem は ADR の番号を `testGroup` の名前やファイルの冒頭の注釈に書くことがある (`modules/golem-preflight/test/PlatesSpec.hs` の 1 行と 61 行)。
- dotfiles のコミット済みの ADR のうち、「受けいれ条件」の節を持つのは [ADR 0122](0122-move-adr-rules-into-skill.md) と [ADR 0123](0123-context-restore-skill.md) の二つで、どちらも項目に番号が無い (`rg -l '^## 受けいれ条件' docs/adr`)。
  番号の付いた不変条件を持つ ADR は無い。[ADR 0118](0118-split-instructions-into-skills.md) から 0123 の不変条件は、どれも「なし」である。
  [ADR 0014](0014-fix-remaining-audit-items.md)、[0055](0055-improvements-2026-10-13.md)、[0057](0057-remaining-improvements-2.md) には `I1` のような番号があるが、これは監査の改善項目の番号で、不変条件ではない ([ADR 0055](0055-improvements-2026-10-13.md) の 7 行「I1〜I5」)。
- dotfiles の zsh のテストの名前は、内容を書いた日本語の文で、不変条件の番号を含まない (例: `zsh/tests/fzf-history-preview.test.zsh` の 37 行の `check "番号とタブを外す" …`)。ADR のファイルを括弧で添えるものはある (`zsh/tests/fzf-command-finder.test.zsh` の 39 行の `(fworktree。docs/adr/0070)`)。
- Golem (`tett23/golem`、コミット `85bc0377`) の `testCase` の名前を、`rg -o --no-filename 'testCase "[^"]*"' modules` で取り出して数えた。
  - 全部で 5903 件ある。
  - `I<数>` で始まるもの (`grep -cE '^testCase "I[0-9]+'`) は 399 件で、そのうち名前に ADR の参照 (`ADR NNNN` か `docs/adr`) を含むもの (さらに `grep -cE 'ADR [0-9]{4}|docs/adr'`) は 23 件である。
  - 末尾の括弧に ADR を書くもの (`grep -cE '\([^)]*(ADR|docs/adr)[^)]*\)"$'`) は 738 件である。
  - 末尾の括弧のうち、ルートの `docs/adr/` の ADR の書き方は、`(docs/adr/NNNN)` が 166 件 (`grep -cE '\(docs/adr/[0-9]{4}\)"$'`)、`(docs/adr ADR NNNN)` が 151 件 (`'\(docs/adr ADR [0-9]{4}\)"$'`)、`(docs/adr NNNN)` が 21 件 (`'\(docs/adr [0-9]{4}\)"$'`) である。モジュールを書かない `(ADR NNNN)` が 58 件 (`'\(ADR [0-9]{4}\)"$'`) ある。
  - `I<数>` で始まるか末尾の括弧に ADR を書くもの (`grep -cE '^testCase "I[0-9]+|\([^)]*(ADR|docs/adr)[^)]*\)"$'`) は 1121 件、名前のどこかに ADR の参照を含むもの (`grep -cE 'ADR [0-9]{4}|docs/adr'`) は 832 件である。
  - `I` と `A` のほかの番号もある (`modules/golem-layout/test/AkiTableSpec.hs` の 27 行の `ADR0241-F5`、`modules/golem-driver/test/AlignSpaceSpec.hs` の 40 行の `S1 of docs/adr ADR 0284`)。
- Golem の `CLAUDE.md` も、ADR の構成と不変条件の決まりを持つ (13 行など)。
- 共通の指示 (`.claude/CLAUDE.md` と `codex/AGENTS.md`) の「チャットでのADR表記」は、モノレポでは ADR を `<module name> ADR NNNN` と書くとしている。ルートの ADR の書き方は決めていない。
- adr-guard は、コミット済みの ADR の書き換えを止める。意図して書き換えるときは、その書き換えだけの一つのコミットにし、pre-commit hook は環境変数 `ADR_GUARD_ALLOW=<理由>`、CI はコミットのメッセージのトレーラー `ADR-Guard-Allow: <理由>` で許す (dotfiles の `docs/specifications.md` の adr-guard の節)。

推測: Rust の `#[test]` を付けた関数の名前のように、名前を識別子で付ける仕組みでは、空白とハイフンを使えない (言語の決まり。手元のリポジトリでは確かめていない)。

## 実装すること

`agents/skills/adr/SKILL.md` に、次の決まりを書く。

### 番号

- 不変条件の番号は、ADR ごとに `I1`、`I2`、… とする。受けいれ条件の番号は `A1`、`A2`、… とする。ほかの文字の番号 (`F5`、`S1` など) は、不変条件と受けいれ条件には使わない。
- 番号は、ADR を最初にコミットした後は付け直さない。下の「今ある ADR とテストの書き換え」のときだけ例外とする。
- 別の ADR の番号を指すときは、`ADR NNNN I1` と書く。モノレポでは、モジュールの ADR を `<module name> ADR NNNN I1`、ルートの `docs/adr/` の ADR を `root ADR NNNN I1` と書く。モノレポのモジュールに `root` という名前を付けない。
- リポジトリの外の ADR を指すときは、`<リポジトリ> ADR NNNN` と書く (`dotfiles ADR 0124`、`tett23/adr-guard ADR 0022` など)。

### 不変条件の節の形

- 番号ごとに、`I1`: の後に、テストの述語として書ける形の性質を一文で書く。
- 節の終わりに、境界の入力の表を一つ置く。列は「入力」「期待」「不変条件」の 3 つとし、「不変条件」の列には、その入力で確かめる番号 (`I1`、`I1, I2` など) を書く。境界の入力は、空、一つ、ちょうど収まる、一つあふれる、などである。

### テストの名前

- テストの名前は、テストの仕組みが入れ子にするとき (tasty の `testGroup` など) も、一つのテストの名前 (`testCase` や `check` の名前) だけで決まりを満たす。入れ子の外側の名前に ADR を書いても、内側の名前に書くことを省かない。
- 名前を文字列で付けるテスト: 名前の先頭に `ADR <NNNN> I<番号>: ` (受けいれ条件は `ADR <NNNN> A<番号>: `) を置き、その後に内容を書く。
  - 例: `check "ADR 0124 I1: 空の入力は空を返す" …`、`testCase "ADR 0124 I1: an empty input returns empty"`。
  - モノレポでは、`ADR` の前にモジュールの名前を置く (`golem-pdf ADR 0006 I2: …`、ルートの ADR は `root ADR 0232 I10: …`)。
- 名前に空白とハイフンを使えないとき (識別子で名前を付けるテストなど) は、空白とハイフンの代わりに `_` を使う。
- 名前を識別子で付けるテスト: 名前を `adr<NNNN>_i<番号>_<内容>` (受けいれ条件は `adr<NNNN>_a<番号>_<内容>`) とする。
  - 例: `adr0124_i1_empty_input_returns_empty`。
  - モノレポでは、モジュールの名前のハイフンを `_` にして頭に置く (`golem_pdf_adr0006_i2_…`、ルートの ADR は `root_adr0232_i10_…`)。
  - 言語やテストの仕組みが名前の接頭辞を決めているとき (Go の `Test` など) は、その接頭辞の後に同じ形を置く (`TestAdr0124_i1_…`)。
- 一つのテストが二つ以上の番号を確かめるとき:
  - 同じ ADR の番号は、文字列では `ADR 0124 I1, I2: …`、識別子では `adr0124_i1_i2_…` とつなぐ。
  - 二つの ADR にまたがるときは、文字列では `ADR 0122 I1, ADR 0124 I2: …`、識別子では `adr0122_i1_adr0124_i2_…` とする。
  - 番号の区切りは、日本語の名前でも英語の名前でも、`, ` (半角のカンマと空白) とする。
- 受けいれ条件は、自動のテストで確かめられるものにはテストを書き、上の形の名前を付ける。手で確かめるものは、テスト設計にその手順を書き、番号を添える。
- 後の ADR が前の ADR の不変条件を変えたときは、変えた不変条件を確かめるテストの名前を、変えた側の ADR の番号に付け直す。

### ルートの ADR のチャットでの表記

- 共通の指示 (`.claude/CLAUDE.md` と `codex/AGENTS.md`) の「チャットでのADR表記」に、「ルートの `docs/adr/` の ADR は `root ADR NNNN` と書く」を足す。

### 今ある ADR とテストの書き換え

- 決まりを入れた後に、各リポジトリで一度だけ、今あるコミット済みの ADR の不変条件と受けいれ条件と、それを確かめる今あるテストの名前を、この決まりの形に書き換える。
- 書き換えるのは、不変条件と受けいれ条件の番号と、テストの名前だけである。不変条件と受けいれ条件の中身は変えない。中身を変えたいときは、新しい ADR を作る。改善項目など、不変条件でも受けいれ条件でもない番号は変えない。
- テストに付ける ADR と番号は、名前だけからは決まらないことがある (Golem では、ADR を `testGroup` の名前や注釈に書いている)。そのときは、テストのファイルの注釈、`testGroup` の名前、ADR のテスト設計を読んで決める。決められないテストは書き換えず、一覧にして本人に示す。
- ADR の書き換えは、その書き換えだけの一つのコミットにし、pre-commit hook は `ADR_GUARD_ALLOW=<理由>`、CI はコミットのメッセージのトレーラー `ADR-Guard-Allow: <理由>` で許す。理由には、この ADR を `dotfiles ADR 0124` のように、そのリポジトリの外から見て分かる書き方で書く。
- dotfiles の書き換えは、この ADR の実装に含める。対象は、[ADR 0122](0122-move-adr-rules-into-skill.md) と [ADR 0123](0123-context-restore-skill.md) の受けいれ条件の項目に `A1` から番号を振ることである。テストの名前を書き換える対象は無い。
- ほかのリポジトリ (Golem など) の書き換えは、そのリポジトリで、そのリポジトリの ADR を作って行う。その ADR で、そのリポジトリの `CLAUDE.md` などにある同じ決まりも直す。

## 実装しないこと

- テストの名前の形を、CI や adr-guard で機械的に検査すること。後で作る監査のスキル ([ADR 0126](0126-audit-skill.md)) で扱う。
- ほかのリポジトリの ADR とテストを、dotfiles の作業の中で書き換えること。
- ADR のファイルを括弧で添えるだけのテストの名前 (`(fworktree。docs/adr/0070)` など) を書き換えること。不変条件や受けいれ条件の番号を確かめるテストではない。

## 不変条件

なし。ADR とテストの書き方の決まりと、その書き換えの手順だけを決める ADR で、入力に対する振る舞いを決めない。

## 受けいれ条件

- A1: `agents/skills/adr/SKILL.md` に、「実装すること」の決まりがすべて書いてある。共通の指示の「チャットでのADR表記」に、ルートの ADR の書き方がある。
- A2: [ADR 0122](0122-move-adr-rules-into-skill.md) と [ADR 0123](0123-context-restore-skill.md) の受けいれ条件の項目が、`A1` から始まる番号を持ち、中身は変わっていない。その書き換えのコミットが、`ADR-Guard-Allow` のトレーラーを持ち、書き換えだけを含む。
- A3: この ADR の後に書く ADR は、不変条件か受けいれ条件を持つとき、それに決まりの形の番号を付けている。振る舞いを決める ADR のテストの名前には、その番号が入っている。

## テスト設計

文書の決まりと書き換えの手順なので、CI の自動のテストは書かない。

- A1: 実装の後に、`agents/skills/adr/SKILL.md` と共通の指示を「実装すること」の各項目と突き合わせ、`close-reading` で精読する。
- A2: 書き換えの前と後の [ADR 0122](0122-move-adr-rules-into-skill.md) と [ADR 0123](0123-context-restore-skill.md) を `git diff` で比べ、変わったのが受けいれ条件の各項目の頭の番号だけであることを確かめる。書き換えのコミットのメッセージにトレーラーがあり、pre-commit hook (`ADR_GUARD_ALLOW`) と CI の `adr` ジョブが通ることを確かめる。
- A3: この ADR の後で最初に書く ADR で、番号とテストの名前が決まりのとおりであることを、精読と本人のレビューで確かめる。

## トレードオフ

- テストの名前が長くなる。識別子の名前は、内容の部分を短くする。
- Golem の書き換えは大きい。`testCase` の 5903 件のうち、番号で始まるか末尾に ADR を書くものが 1121 件ある (「調査した事項」)。付ける ADR を名前ごとに読んで決めるものも多い。Golem の書き換えは、Golem の ADR で範囲と進め方を決める。
- テストの名前の中の ADR と、`testGroup` や注釈の中の ADR が二重になる。名前だけで探せることを優先する。

## 参考文献

- dotfiles の `agents/skills/adr/SKILL.md`、`zsh/tests/`、`docs/specifications.md` の adr-guard の節、[ADR 0122](0122-move-adr-rules-into-skill.md)、[ADR 0123](0123-context-restore-skill.md)
- Golem (`tett23/golem`、コミット `85bc0377`) の `modules/*/test/`、`modules/golem-eval/golem-eval.cabal`、`CLAUDE.md`
