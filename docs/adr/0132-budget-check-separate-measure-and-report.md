# ADR 0132: budget-check の計測と issue への書き込みを分け、計測のコマンドにトークンを見せない

Status: accepted-pending

## 文脈

[ADR 0128](0128-budget-check-in-ci.md) は、`bin/budget-check` が予算の一覧の計測のコマンドを動かし、違反を issue に書き込むと決めた。
その CI のジョブの例では、一つのステップに `GH_TOKEN` (`issues: write` の権限を持つ `GITHUB_TOKEN`) を渡し、同じプロセスで計測と書き込みを行う。

2026-11-16 のセキュリティの監査 ([docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md) の指摘 8) は、計測のコマンドに `GH_TOKEN` が見えることを挙げた。
`bin/budget-check` は計測のコマンドを `sh -c` で動かし、環境をそのまま渡すためである。
計測のコマンドは、リポジトリのビルドやベンチマークを動かすので、依存のパッケージのコードも動く。
そのため、依存のパッケージが侵されると、そのトークンで issue を書き換えられる。
本人は、この点をかなり気にしていて、`.env` から取るか、`gh` の仕組みでうまく扱う方法を探すよう頼んだ。

そのため、この ADR で、計測と書き込みを別のジョブに分け、計測のジョブにはトークンを置かないと決める。

## 調査した事項

- `bin/budget-check` は、計測のコマンドを `output=$(cd "$root" && sh -c "$cmd" 2>/dev/null)` で動かす (`bin/budget-check` の 140 行)。環境変数を消していないので、`GH_TOKEN` は計測のコマンドに見える。
- `actions/checkout` の `persist-credentials` の既定は `true` で、トークンをチェックアウトした先の git の設定に書く (`actions/checkout` の `v7` の `action.yml` の 52〜54 行。`gh api 'repos/actions/checkout/contents/action.yml?ref=v7'` で読んだ)。そのため、`GH_TOKEN` を環境から消しても、同じジョブの中で `persist-credentials` を `false` にしないと、計測のコマンドは git の設定からトークンを読める。
- GitHub Actions のトークンの権限 (`permissions`) は、ジョブごとに決まる。同じジョブの中では、ステップを分けても、前のステップが `$GITHUB_ENV` に書いた環境変数が後のステップに渡る (GitHub Actions の仕様。この ADR では動かして確かめていない)。そのため、計測とトークンを使う書き込みを同じジョブの別のステップに分けても、計測のコマンドが後のステップに手を入れられる。
- `gh api` のエンドポイントの `{owner}` と `{repo}` は、今のディレクトリのリポジトリか、環境変数 `GH_REPO` のリポジトリで埋まる (`gh api --help` の 6〜9 行)。`gh issue` なども `GH_REPO` を使う (`gh help environment`)。そのため、書き込みのジョブは、対象のリポジトリをチェックアウトせずに `gh` を使える。
- ジョブの間でファイルを渡す `actions/upload-artifact` と `actions/download-artifact` の最新の版は、それぞれ `v7.0.2` と `v8.0.2` である (2026-11-17 に `gh api repos/actions/<名前>/releases/latest --jq .tag_name` で読んだ)。
- issue には、本文とコメントのほかに、ファイルを付けられる。
  - `gh` の `v2.99.0` から、`gh issue create`、`gh issue comment` などの `--attach` で、画像と動画 (PNG、JPEG、GIF、WebP、SVG、MP4、MOV、WebM) を付けられる ([GitHub の 2026-09-01 の changelog](https://github.blog/changelog/2026-09-01-github-cli-media-in-issues-pull-requests-and-comments))。手元の `gh 2.104.0` の `gh issue comment --help` は、`--attach` のときだけ、本文の中のローカルのパスを、上げたファイルへの参照に書き換えると書いている。
  - 2026-10-28 から、issue artifact (issue に付ける Markdown の文書、HTML の文書、リンク) が public preview である ([GitHub の 2026-10-28 の changelog](https://github.blog/changelog/2026-10-28-issue-artifacts-are-now-in-public-preview))。HTML の文書は、描画した姿で見られる。`gh issue artifact` の `create`、`edit`、`delete` などで扱う (`gh issue artifact --help`)。`GITHUB_TOKEN` の `issues: write` で作れるかは、確かめていない。
  - `bin/budget-check` が呼ぶ `gh` は、`gh issue list`、`gh issue create --title … --label … --body …`、`gh api` のコメントの読み出し、`gh issue comment … --body …` だけで、`--attach` も `gh issue artifact` も使わない (`bin/budget-check` の 151、171、176、220 行)。そのため、本文は `--body` の文字列のまま書かれ、本文の中のパスからファイルは上がらない。
- 手元では、`gh` は自分が保存した認証情報 (`gh auth login` の結果) を使い、`GH_TOKEN` は要らない。CI では、トークンは Actions がジョブに渡すもので、ファイルに置く必要は無い。

`.env` からトークンを取る案は、次の理由でとらない。
手元では、`gh` が自分の認証情報を持つので、`.env` は要らない。
CI では、トークンを `.env` に書くと、同じジョブの計測のコマンドがそのファイルを読めるので、環境変数に置くのと変わらない。

## 実装すること

### `bin/budget-check` の使いかた

使いかたを次の 3 つにする。

- `budget-check [--dry-run] [--fail-on-violation] [予算の一覧のパス]`: 今と同じく、計測と書き込みを一つのプロセスで行う。手元で動かすときに使う。
- `budget-check --measure-to <結果のファイル> [予算の一覧のパス]`: 計測だけを行い、結果をファイルに書く。`gh` を呼ばない。
- `budget-check --report-from <結果のファイル> [--dry-run] [--fail-on-violation]`: 結果のファイルを読み、issue への書き込みだけを行う。計測のコマンドを動かさない。git のリポジトリの中でなくてもよく、リポジトリの外で動かしたことをエラーにしない。

`--measure-to` と `--report-from` を一緒に渡したとき、`--measure-to` に `--dry-run` か `--fail-on-violation` を添えたとき、`--report-from` に予算の一覧のパスを添えたときは、エラーとして終了コード 1 で終わる。

### 計測のコマンドの環境

計測のコマンドは、サブシェルで `GH_TOKEN`、`GITHUB_TOKEN`、`GH_ENTERPRISE_TOKEN`、`GITHUB_ENTERPRISE_TOKEN` を `unset` してから動かす。
一つのプロセスで動かすときも、`--measure-to` のときも同じにする。

ただし、この `unset` は、誤ってトークンを計測のコマンドに渡さないためのもので、トークンを守る境界ではない。
一つのプロセスで動かすときは、計測のコマンドの後に、同じプロセスがトークンを持って `gh` を呼ぶ。
そのため、計測のコマンドは、`PATH` の先の `gh` を置き換えるなどして、トークンに届きうる。
トークンを守るのは、計測と書き込みのジョブを分けることだけである。
そのため、CI では一つのプロセスの形を使わない。

### 結果のファイル

結果のファイルは、テキストで、1 行目を `budget-check-results 1<US><リポジトリのルートから見た予算の一覧の相対パス><US><コミット>` とする。
`<US>` は `\037` (ユニットセパレーター) である。
`<コミット>` は、`$GITHUB_SHA` か、無ければ `git rev-parse HEAD` の値で、issue の本文とコメントに書く。
2 行目からは、予算ごとに次のどちらかの行を書く。

- `R<US>名前<US>指標と単位<US>比較<US>値<US>計測のコマンド<US>ADR<US>計測の値`: 計測できた予算。
- `E<US>場所<US>理由`: エラーの予算 (セルの数、名前の重なり、比較、値、計測のコマンドの失敗、計測の値)。

`--measure-to` は、予算の一覧が読めないとき ([ADR 0128](0128-budget-check-in-ci.md) で終了コード 1 になる場合) は、結果のファイルを書かずに 1 で終わる。
`--measure-to` は、結果のファイルの親のディレクトリが無ければ作る。
パスを省いて `docs/budgets.md` が無いとき、または表に行が無いときは、1 行目だけの結果のファイルを書き、0 で終わる。
予算のエラーは結果のファイルに書き、0 で終わる。

`--report-from` は、1 行目が上の形でないとき、エラーとして 1 で終わる。
`R` の行の比較、値、計測の値は、[ADR 0128](0128-budget-check-in-ci.md) と同じ決まりで確かめ直し、合わない行と `E` の行はエラーの予算とする。
issue の題、コメントを足すかの決め方、本文とコメントの中身は、[ADR 0128](0128-budget-check-in-ci.md) の「実装すること」の 8〜14 と同じにする。
終了コードは、エラーの予算があれば 1、エラーが無く違反があり `--fail-on-violation` があれば 2、それ以外は 0 とする。
`--report-from` が呼ぶ `gh` は、今と同じく `gh issue list`、`gh issue create`、`gh issue comment`、`gh api` のコメントの読み出しだけとし、`--attach`、`gh issue artifact`、そのほかの書き込みを使わない。
結果のファイルの中身が書き込みに届く先を、issue の題、本文、コメントの文字列に限るためである。

### CI のジョブの例

`agents/skills/conformance-audit/SKILL.md` の CI のジョブの例を、次の二つのジョブに置き換える。

```yaml
budget-measure:
  runs-on: ubuntu-latest
  permissions:
    contents: read
  steps:
    - uses: actions/checkout@v7
      with:
        persist-credentials: false
    - uses: actions/checkout@v7
      with:
        repository: tett23/dotfiles
        ref: <固定するコミット>
        path: .dotfiles
        persist-credentials: false
    - run: .dotfiles/bin/budget-check --measure-to "$RUNNER_TEMP/budget/results"
    - uses: actions/upload-artifact@v7
      with:
        name: budget-results
        path: ${{ runner.temp }}/budget/results
budget-report:
  needs: budget-measure
  runs-on: ubuntu-latest
  permissions:
    contents: read
    issues: write
  concurrency:
    group: budget-${{ github.repository }}
  steps:
    - uses: actions/checkout@v7
      with:
        repository: tett23/dotfiles
        ref: <固定するコミット>
        path: .dotfiles
        persist-credentials: false
    - uses: actions/download-artifact@v8
      with:
        name: budget-results
        path: ${{ runner.temp }}/budget
    - run: .dotfiles/bin/budget-check --report-from "$RUNNER_TEMP/budget/results"
      env:
        GH_TOKEN: ${{ github.token }}
        GH_REPO: ${{ github.repository }}
```

書き込みのジョブは、対象のリポジトリをチェックアウトせず、計測のコマンドを動かさない。
スキルには、計測のジョブにトークンを渡さないこと、その理由 (計測のコマンドは依存のパッケージのコードを動かす)、CI では一つのプロセスの形を使わないことを書く。
どのイベントで動かすかは、[ADR 0128](0128-budget-check-in-ci.md) のとおり各リポジトリの ADR で決める。
スキルには、fork からの `pull_request` ではトークンが書き込めず、書き込みのジョブが 1 で終わることを書き、既定のブランチへの `push` で動かす例を添える。
この例が各リポジトリで通るか (権限、artifact の受け渡し) は、各リポジトリに足すときに、そのリポジトリの ADR で動かして確かめる。

### そのほか

- `docs/specifications.md` の `bin/budget-check` の使いかたを、上の 3 つに直す。
- [ADR 0128](0128-budget-check-in-ci.md) のステータスを、次の二つの要素を持つ `superseded` にする。
  - `{"part":"実装すること (スクリプト bin/budget-check)","by":["docs/adr/0132-budget-check-separate-measure-and-report.md"],"kind":"supplement"}`: 使いかたと結果のファイルを足す。
  - `{"part":"実装すること (そのほか: CI のジョブの例)","by":["docs/adr/0132-budget-check-separate-measure-and-report.md"],"kind":"replace"}`: CI のジョブの例を置き換える。

## 実装しないこと

- `.env` などのファイルからトークンを読むこと (上の調査のとおり)。
- 計測のコマンドを、手元で `gh` の認証情報から隔てること。手元で動かす計測のコマンドは、本人が自分のリポジトリで動かすコマンドなので、`gh auth token` で読めても、手元のほかのコマンドと同じ扱いにする。
- 計測のジョブと書き込みのジョブを、dotfiles の CI に足すこと ([ADR 0128](0128-budget-check-in-ci.md) と同じく、dotfiles には予算が無い)。
- 2026-11-16 の ADR 違反の監査が挙げた `bin/budget-check` の不具合 (印の正規表現、空の最後のセル) を、この ADR で直すこと。[ADR 0128](0128-budget-check-in-ci.md) の不変条件に合わせる直しなので、ADR を作らずに直す。

## 不変条件

- I1: 計測のコマンドの環境には、`GH_TOKEN`、`GITHUB_TOKEN`、`GH_ENTERPRISE_TOKEN`、`GITHUB_ENTERPRISE_TOKEN` が無い。呼び出したときにこれらが設定されていても同じである。
- I2: `--measure-to` のとき、`gh` は一度も呼ばれない。
- I3: `--report-from` のとき、計測のコマンドは一度も動かない。
- I4: 同じ予算の一覧と同じ issue の状態について、`--measure-to` の後に `--report-from` を動かしたときの `gh` の書き込みの呼び出しと終了コードは、一つのプロセスで動かしたときと同じである。
- I5: `--report-from` は、1 行目が `budget-check-results 1<US><パス>` の形でないファイルについて、`gh` を一度も呼ばずに終了コード 1 で終わる。
- I6: `--report-from` は、`R` の行の比較、値、計測の値が [ADR 0128](0128-budget-check-in-ci.md) の決まりに合わないとき、その予算について issue を作らず、コメントも足さない。
- I7: `--measure-to` は、予算の一覧が読めないとき、結果のファイルを作らずに終了コード 1 で終わる。`docs/budgets.md` が無いとき (パスを省いたとき) と表に行が無いときは、1 行目だけの結果のファイルを作り、終了コード 0 で終わる。
- I8: `--measure-to` と `--report-from` を一緒に渡したとき、計測のコマンドも `gh` も動かさずに終了コード 1 で終わる。
- I9: `--report-from` が呼ぶ `gh` の第 1、第 2 の引数は、`issue list`、`issue create`、`issue comment`、`api` のどれかであり、どの引数も `--attach` ではない。`api` の呼び出しは読み出しだけである (`-X`、`--method`、`-f`、`-F`、`--input` を持たない)。

境界の入力:

| 入力 | 期待 | 不変条件 |
| --- | --- | --- |
| `GH_TOKEN=x` を設定し、計測のコマンドが `GH_TOKEN` の有無を数で出す | 「無い」の数が出る | I1 |
| `GITHUB_TOKEN=x` で同じ | 「無い」の数が出る | I1 |
| `--measure-to` で違反の予算 | 結果のファイルに `R` の行。`gh` は呼ばれない | I2 |
| `--measure-to` で計測のコマンドが失敗 | 結果のファイルに `E` の行。終了コード 0 | I2 |
| `--measure-to` で、ファイルはあるが予算の表が無い | 結果のファイルを書かず、終了コード 1 | I2, I7 |
| `--measure-to` で、パスを省き `docs/budgets.md` が無い | 1 行目だけの結果のファイル。終了コード 0 | I7 |
| `--measure-to` で、表に行が無い | 1 行目だけの結果のファイル。終了コード 0 | I7 |
| 1 行目だけの結果のファイルを `--report-from` に渡す | `gh` を呼ばず、終了コード 0 | I4 |
| `--report-from` を git のリポジトリの外で動かす | リポジトリの外を理由に 1 で終わらない | I4 |
| `--report-from` で、計測のコマンドがファイルを作るコマンドの行 | そのファイルは作られない | I3 |
| 違反、満たす、エラーの三つの予算を、分けて動かす場合と一つで動かす場合 | 書き込みの呼び出しと終了コードが同じ | I4 |
| 空のファイルを `--report-from` に渡す | 1 で終わり、`gh` は呼ばれない | I5 |
| 1 行目が `budget-check-results 2…` | 1 で終わる | I5 |
| `R` の行の計測の値が `abc` | その予算はエラー。終了コード 1 | I6 |
| `R` の行の比較が `<` | その予算はエラー | I6 |
| `R` の行だけで `E` の行が無い (エラー無し、違反あり、`--fail-on-violation`) | 終了コード 2 | I4 |
| `--measure-to` と `--report-from` を一緒に渡す | 何も動かさず 1 で終わる | I8 |
| `R` の行の名前と計測のコマンドに `![x](./a.png)` と `--attach ./a.png` を含め、違反の新しい issue とコメントを書かせる | 偽の `gh` の記録に、I9 の外の呼び出しも `--attach` の引数も無い | I9 |

## 受けいれ条件

- A1: `zsh/tests/budget-check.test.zsh` の、上の不変条件の番号を持つテストと、[ADR 0128](0128-budget-check-in-ci.md) の不変条件のテストがすべて通る。dotfiles の CI の `zsh-tests` と shellcheck のジョブも通る。
- A2: `conformance-audit` のスキルの CI のジョブの例が、計測と書き込みの二つのジョブに分かれ、計測のジョブにトークンが無い。

## テスト設計

- A1: 境界の入力の表の行を、それぞれテストにする。テストを先に書いて失敗させてから、スクリプトを直す。
  - I1 は、計測のコマンドを `[ -z "${GH_TOKEN+x}" ] && echo 0 || echo 1` のような、変数の有無を数で出すコマンドにし、`<= 0` の予算が満たされることで確かめる。
  - I4 は、同じ一覧と同じ偽の `gh` の初めの状態から、二つの動かし方の偽の `gh` の記録を比べる。`GITHUB_SHA` などの環境変数は、二つの動かし方で同じにする。
- A2: 実装の後に、スキルを読み、`close-reading` で精読する。CI の例は、各リポジトリに足すときに、そのリポジトリの ADR で動かして確かめる。

## トレードオフ

- CI のジョブが二つになり、結果を artifact で渡すので、ジョブの例が長くなる。
- 書き込みのジョブは、計測のジョブが作った結果のファイルを信じる。計測のジョブで動くコードは、結果のファイルを書き換えて、ラベル `budget-violation` の issue とコメントを、任意の題と本文 (メンションやリンクを含む) で、任意の数だけ作れる。ただし、トークンそのものには届かないので、issue の書き込みのほかのことはできない。書き込みのジョブは `--attach` と `gh issue artifact` を使わないので (I9)、画像、動画、HTML の文書は付けられない。本文の中のリンクで、外のファイルを指すことはできる。
- 手元で一つのプロセスで動かすときは、計測のコマンドが `gh auth token` で手元の認証情報を読める。これは手元のほかのコマンドと同じ扱いにする。

## 参考文献

- dotfiles の [ADR 0128](0128-budget-check-in-ci.md)
- [docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md)
- `actions/checkout` の `v7` の `action.yml`
- `gh api --help`、`gh help environment`
