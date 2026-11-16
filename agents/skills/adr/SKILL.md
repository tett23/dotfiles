---
name: adr
description: ADR (docs/adr/) の決まり。採択の記録、修正と破棄、adr-guard の入れ方、ファイルの置き場所と名前、テンプレート、不変条件の書き方、精読、未実装の ADR の実装。ADR を書く・直す・採択する・実装する・破棄するとき、リポジトリに adr-guard を入れるとき、未実装の ADR をまとめて実装するときに使う。これらの前に必ず読む。
---

# ADR（docs/adr/）

ADR は、サブエージェントに書かせず、既定のモデルで書く。
調べものはサブエージェントに任せてよいが、ADR に書く事実は、根拠のコマンドと出力が返ったものだけにする。

採択されたら、まず `Status: proposed` のまま ADR をコミットし、次のコミットでステータスを `accepted` (実装済み) か `accepted-pending` (未実装) に変える。adr-guard は、追加の時点で `accepted` の ADR と、決まりにない状態の遷移を拒否する。
仕様を変更したくなった場合は、新たに修正用のADRを作成する。元のADRを書きかえてはいけない。
修正用の ADR が採択されたら、元の ADR のステータスを `superseded [{"part":null,"by":["docs/adr/NNNN-....md"]}]` にする。一部だけを変えたときは、`part` にその部分の名前 (節の名前など) を書く。`adr-guard trace` で修正の連なりをたどれる。
ADRを破棄する場合は、ステータスを `discarded` にして、理由をdocs/specifications.mdに記述する。

## ステータスと状態の遷移

ADR の状態は、ステータスの行 `Status: <値>` で表し、決まった遷移でだけ変えられる。
adr-guard の pre-commit hook と CI (`check-range`) は、コミットの前の状態からコミットの後の状態への遷移を検査し、決まりにない遷移を拒否する。
この検査は `--allow-status` と `ADR_GUARD_ALLOW` でも免除されない
([tett23/adr-guard ADR 0022](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0022-status-transitions.md) の「コミット時の遷移検査」)。

値は次のとおりである。

| 値 | 意味 |
| --- | --- |
| `proposed` | 提案。レビューを待つ |
| `accepted` | 採択し、実装を終えた |
| `accepted-pending` | 採択し、実装を待つ |
| `superseded [<変更の配列>]` | 採択した後に、後の ADR が変更を記録した |
| `superseded-pending [<変更の配列>]` | 実装を待つ間に、後の ADR が変更を記録した |
| `rejected` | 却下した |
| `discarded` | 破棄した |
| `deprecated` | 採択した後に、使わなくなった |

許される遷移は次のとおりである。
新しい ADR は `proposed` でしか追加できず、採択や却下は後のコミットで記録する。
提案の時点の内容を Git の履歴に残すためである。

| 前 | 後 | 使う場面 |
| --- | --- | --- |
| (無い) | `proposed` | ADR を足す |
| `proposed` | `accepted`・`accepted-pending`・`rejected`・`discarded` | 採択、採択して実装を待つ、却下、破棄 |
| `accepted-pending` | `accepted` | 実装を終えた |
| `accepted-pending` | `superseded [...]`・`superseded-pending [...]` | 後の ADR が変更を記録した (実装を終えたか、まだか) |
| `superseded-pending [...]` | `superseded [...]` | 実装を終えた。変更の配列は前と同じにする |
| `accepted` | `superseded [...]` | 後の ADR が変更を記録した |
| `superseded [...]`・`superseded-pending [...]` | 同じ値で、変更の配列だけ違うもの | さらに後の ADR が変更を記録した |
| `accepted`・`accepted-pending`・`superseded [...]`・`superseded-pending [...]` | `deprecated` | 使わなくなった |

同じ状態を別の書き方に移すだけの変更 (旧形式の `ステータス: 採択` を `Status: accepted` にするなど) は、遷移として検査を通る。
`rejected`・`discarded`・`deprecated` からの遷移は無い。

変更の配列の要素は、`{"part":<部分の名前か null>,"by":[<修正先>],"kind":<種類>,"note":<注記>}` である。
`part` が `null` のときは ADR 全体を、文字列のときは節の名前などの一部を指す。
修正先は、リポジトリのルートからの相対パスか、`https://` で始まる URL である。
`kind` は `"replace"` (置換。省いたときの値)、`"supplement"` (補足)、`"note"` (注記) のどれかで、`note` は改行を含まない文字列である。
注記は修正先を持たず (`"by":[]`)、`note` を必ず持つ。補足や注記だけを記録するときも、`superseded` か `superseded-pending` を使う
([tett23/adr-guard ADR 0025](https://github.com/tett23/adr-guard/blob/v0.13.1/docs/adr/0025-extend-canonical-status-amendments.md))。
修正の連なりは `adr-guard trace` でたどれる。

変更を不可にする方法は以下にある。リポジトリを初期化するときにはREADMEに従うこと。
https://github.com/tett23/adr-guard

具体的には、次の 4 つを行う。Claude Code と Codex の hook は全体の設定 (`~/.claude/settings.json`、`~/.codex/hooks.json`) で有効なので不要。

1. `.githooks/pre-commit` を置き、実行権限を付ける。ほかの検査と並べる場合は、`exec` の行を最後に置く。

   ```sh
   #!/bin/sh
   exec adr-guard pre-commit --allow-status --allow-links
   ```

2. clone ごとに `git config core.hooksPath .githooks` を実行する (README にも手順を書く)。
3. `docs/adr/.gitkeep` を置く。モノレポでは、各モジュールの `docs/<module name>/adr/.gitkeep` も置く (dotfiles の docs/adr/0129)。
4. CI に adr-guard の `adr` ジョブを足す (adr-guard の README の例のとおり)。

## ADRの構成

docs/adr/ に配置する。ファイル名には `0001-feature-details.md` のように連番のprefixをつけなくてはいけない。連番以降はkebab-caseで、内容を表すような人間に可読な名前をつける。

## ADRの中身

ADRは以下のような内容を記載する。ステータスはこのADRがどのような状態にあるかを示す。データ構造やアルゴリズムを変更する場合は、その節も立てる。仕様の調査に使った文献はADRの末尾に含めること。そのほか、仕様検討時のログとして残したほうがよいことがあれば節を立てる。

```
# ADR 0001: タイトル

Status: {proposed／accepted／accepted-pending／superseded [...]／superseded-pending／rejected／discarded／deprecated}

## 文脈

## 調査した事項

ここには実際に調査して確かめたことだけを書く。推測を書く場合は、別の節を立てるか、ほかの節に付記し、推測であることを明記する。

## 実装すること

## 実装しないこと

## 不変条件

## 受けいれ条件

## テスト設計

## トレードオフ

## 参考文献

（ない場合はなしと記載）
```

振る舞いを決める ADR は、「不変条件」の節を持つ。どの入力でも成り立つ性質を、テストの述語として書ける形で一つずつ番号を付けて書き、境界の入力（空、一つ、ちょうど収まる、一つあふれる、など）の表を添える。テストの名前には、その番号を入れる。不変条件を書けない ADR（設定の値や手順だけを決めるもの）は、その節に「なし」と理由を書く。

## 番号とテストの名前 (dotfiles の docs/adr/0124)

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

### 今ある ADR とテストの書き換え

- 決まりを入れた後に、各リポジトリで一度だけ、今あるコミット済みの ADR の不変条件と受けいれ条件と、それを確かめる今あるテストの名前を、この決まりの形に書き換える。
- 書き換えるのは、不変条件と受けいれ条件の番号と、テストの名前だけである。不変条件と受けいれ条件の中身は変えない。中身を変えたいときは、新しい ADR を作る。改善項目など、不変条件でも受けいれ条件でもない番号は変えない。
- テストに付ける ADR と番号は、名前だけからは決まらないことがある (Golem では、ADR を `testGroup` の名前や注釈に書いている)。そのときは、テストのファイルの注釈、`testGroup` の名前、ADR のテスト設計を読んで決める。決められないテストは書き換えず、一覧にして本人に示す。
- ADR の書き換えは、その書き換えだけの一つのコミットにし、pre-commit hook は `ADR_GUARD_ALLOW=<理由>`、CI はコミットのメッセージのトレーラー `ADR-Guard-Allow: <理由>` で許す。理由には、この決まりを決めた ADR を `dotfiles ADR 0124` と書く。
- ほかのリポジトリ (Golem など) の書き換えは、そのリポジトリで、そのリポジトリの ADR を作って行う。その ADR で、そのリポジトリの `CLAUDE.md` などにある同じ決まりも直す。

ADR作成後とドキュメント更新後は `adr-guard links --fix` でADRのリンクをチェックし、修正する。

ADR を書いた後は、本人のレビューに出す前に、`close-reading` スキルで ADR を精読し、指摘を直す。

## 未実装ADRの自動実装

`accepted-pending` の ADR を実装するとき (Claude Code では `/goal` で頼まれるとき) の、デフォルトの指示は以下。

```
ADRを全て読み、ステータスが accepted-pending で現状実装可能なものを全て実装。実装が止まりそうなときはその場所を後回しにしてもよい。実装はADRごとにpull-reqを作成する。CIが通ればpull-reqはマージコミットでマージしてよい。停止後、どこを後回しにしたかのレポートをチャットに出力すること。実装のpull-reqには実装が終わったものはステータスを accepted にする変更を含める。
```
