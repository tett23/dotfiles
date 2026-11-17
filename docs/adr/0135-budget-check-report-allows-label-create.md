# ADR 0135: budget-check の書き込みのジョブが呼ぶ gh に、ラベルの用意を含める

Status: accepted

## 文脈

[ADR 0132](0132-budget-check-separate-measure-and-report.md) は、`bin/budget-check --report-from` が呼ぶ `gh` を `gh issue list`、`gh issue create`、`gh issue comment`、`gh api` のコメントの読み出しだけに限った。
この決まりは、不変条件 I9 と「実装すること」の「結果のファイル」の節にある。
I9 の目的は、結果のファイルの中身が書き込みに届く先を、issue の題、本文、コメントの文字列に限ることである。

ところが、[ADR 0128](0128-budget-check-in-ci.md) は、違反の issue を作る前にラベルを用意すると決めている (「実装すること」の 11 の表の「ラベルを用意し、issue を作る」)。
`bin/budget-check` は、そのために `gh label create budget-violation --force --description '予算違反 (bin/budget-check)'` を呼ぶ。
[ADR 0132](0132-budget-check-separate-measure-and-report.md) の調査は、この呼び出しを見落とし、`bin/budget-check` が呼ぶ `gh` として `label create` の無い四つを挙げた (0132 の「調査した事項」)。
そのため、[ADR 0132](0132-budget-check-separate-measure-and-report.md) の I9 は、同じ ADR の I4 (分けて動かしたときの書き込みの呼び出しが、一つのプロセスで動かしたときと同じ) とも、[ADR 0128](0128-budget-check-in-ci.md) とも両立しない。
この食い違いは、[ADR 0132](0132-budget-check-separate-measure-and-report.md) を実装するときに見つかった。

そのため、この ADR で、`--report-from` が呼んでよい `gh` に `gh label create` を足す。

## 調査した事項

- `bin/budget-check` の書き込みの `gh` は、`gh_write label create "$label" --force --description '予算違反 (bin/budget-check)'`、`gh_write issue create …`、`gh_write issue comment …` の三つである (`rg -n 'gh_write ' bin/budget-check`)。読み出しは `gh issue list` と `gh api --paginate --slurp` の二つである。
- `gh label create` の引数は、ラベルの名前 `budget-violation` と説明の固定の文字列だけで、結果のファイルの中身を含まない (0132 の実装のブランチの `bin/budget-check` の `report_budget`。master の `check_budget` でも同じ)。
- `gh label create --help` は、`--force` を「ラベルがあれば、色と説明を書き直す」と、色を渡さないときを「色をランダムに選ぶ」と書いている。`bin/budget-check` は色を渡さないので、`--force` で呼ぶたびにラベルの色が変わるかは、確かめていない。
- `zsh/tests/budget-check.test.zsh` の `ADR 0128 I1: issue を作る前にラベルを用意する` は、`gh label create budget-violation` が一度呼ばれることを確かめている。

## 実装すること

- [ADR 0132](0132-budget-check-separate-measure-and-report.md) の I9 を、次の I1 で置き換える。
- [ADR 0132](0132-budget-check-separate-measure-and-report.md) の「実装すること」の「結果のファイル」の節の「`--report-from` が呼ぶ `gh` は、今と同じく `gh issue list`、`gh issue create`、`gh issue comment`、`gh api` のコメントの読み出しだけとし」の、列挙の部分を、「`gh issue list`、`gh label create`、`gh issue create`、`gh issue comment`、`gh api` のコメントの読み出しだけとし」と読み替える。理由の文 (結果のファイルの中身が届く先を、題、本文、コメントの文字列に限る) は変えない。`gh label create` の引数は固定の文字列なので、この理由は保たれる。
- `zsh/tests/budget-check.test.zsh` の I9 のテストの名前を `ADR 0135 I1: …` に付け直す。
- `docs/specifications.md` の `bin/budget-check` の項に、書き込みの `gh` が `label create`、`issue create`、`issue comment` であることを、この ADR へのリンクを添えて書く。`bin/budget-check` のコメントにも、この ADR を添える。
- [ADR 0132](0132-budget-check-separate-measure-and-report.md) のステータスを、`superseded [{"part":"不変条件 (I9)","by":["docs/adr/0135-budget-check-report-allows-label-create.md"]},{"part":"実装すること (結果のファイル: --report-from が呼ぶ gh)","by":["docs/adr/0135-budget-check-report-allows-label-create.md"]},{"part":"トレードオフ (結果のファイルを偽ったときにできること)","by":["docs/adr/0135-budget-check-report-allows-label-create.md"]},{"part":"調査した事項 (bin/budget-check が呼ぶ gh)","by":[],"kind":"note","note":"呼ぶ gh の列挙で gh label create を見落としていた"}]` にする。0132 の実装はこの ADR と同じブランチで終えるので、`superseded-pending` を経ずに `superseded` にする。
- 0132 の「トレードオフ」の「issue の書き込みのほかのことはできない」を、「issue とラベル `budget-violation` の書き込みのほかのことはできない」と読み替える。

## 実装しないこと

- ラベルを用意する処理を消すこと。ラベルの無いリポジトリで、`gh issue create --label` が失敗するのを防ぐためのものである ([ADR 0128](0128-budget-check-in-ci.md))。
- `gh label create` の引数に、結果のファイルの中身を使うこと。

## 不変条件

- I1: `--report-from` が呼ぶ `gh` の第 1、第 2 の引数は、`issue list`、`label create`、`issue create`、`issue comment`、`api` のどれかであり、どの引数も `--attach` ではない。`api` の呼び出しは読み出しだけである (`-X`、`--method`、`-f`、`-F`、`--input` を持たない)。`label create` の呼び出しの引数の並びは、`label`、`create`、`budget-violation`、`--force`、`--description`、`予算違反 (bin/budget-check)` とちょうど一致する。

境界の入力:

| 入力 | 期待 | 不変条件 |
| --- | --- | --- |
| `R` の行の名前と計測のコマンドに `![x](./a.png)` と `--attach ./a.png` を含め、違反の新しい issue とコメントを書かせる | `gh` の呼び出しが上の五つだけで、`--attach` の引数が無く、`label create` の引数の並びが固定の並びと一致する | I1 |

## 受けいれ条件

- A1: `zsh/tests/budget-check.test.zsh` の `ADR 0135 I1` のテストと、[ADR 0128](0128-budget-check-in-ci.md) と [ADR 0132](0132-budget-check-separate-measure-and-report.md) の不変条件のテストがすべて通る。

## テスト設計

- A1: [ADR 0132](0132-budget-check-separate-measure-and-report.md) の I9 のテストを、名前を付け直して使う。`label create` の呼び出しの引数の並びが、I1 の並びとちょうど一致することを確かめるテストを足す。偽の `gh` は、引数を一つずつ記録する。

## トレードオフ

- 結果のファイルを偽られたときも、`gh label create` でできるのは、ラベル `budget-violation` を作るか、その説明を固定の文字列に書き直すことだけである。色を渡さないので、色が書き直されるかもしれない (確かめていない)。

## 参考文献

- dotfiles の [ADR 0128](0128-budget-check-in-ci.md)、[ADR 0132](0132-budget-check-separate-measure-and-report.md)
