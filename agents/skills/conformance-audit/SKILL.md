---
name: conformance-audit
description: ADR 違反 (実装、テスト、仕様書と README が ADR と合っているか) と予算違反 (決められた性能を満たしているか) を監査する。予算の一覧 (docs/budgets.md) の書き方も持つ。ADR 違反と予算違反の監査を頼まれたとき、本人が「監査」とだけ頼んだとき、予算を決める前、変える前に使う。これらの前に必ず読む。
---

# ADR 違反と予算違反の監査

リポジトリが、決めたこと (ADR と予算) に従っているかを、`auditor` に監査させる手順である (dotfiles の docs/adr/0126)。
セキュリティの監査は、`security-audit` スキルで行う。

## 観点

### ADR 違反

対象は、`accepted` の ADR と、`superseded [...]` の ADR のうち `kind` が `replace` の変更を受けていない部分である。
`supplement` と `note` は、元の部分を置き換えない。

- その「実装すること」と「実装しないこと」が実装に表れているか。
- 不変条件と、自動で確かめる受けいれ条件は、番号ごとに、その番号を名前に持つテストがあり、通るか。テストの名前が `adr` スキルの「番号とテストの名前」の形に合っているか。
- 手で確かめる受けいれ条件は、テスト設計に、番号の付いた確かめの手順があるか。
- 仕様書と README が ADR と合っているか。

`accepted-pending` と `superseded-pending` の ADR は違反に数えず、「未実装」の一覧として別に返す。

### 予算違反

予算の一覧と ADR の受けいれ条件の予算を集め、計測の記録 (`docs/benchmarks/` など) か、リポジトリの計測の手順で得た値と比べる。
計測できなかった予算は「未確認」とする。
予算の一覧も ADR の予算も無いときは、この観点に「予算なし」と返す。

## 予算の一覧

置き場所は `docs/budgets.md` である。
モノレポでモジュールごとに持つときは `docs/<module name>/budgets.md` に置く。

予算の一覧は、見出しの行が `| 名前 | 指標と単位 | 比較 | 値 | 計測のコマンド | ADR |` の表とし、予算ごとに一行を書く。

- 「比較」は `<=` (値が上限) か `>=` (値が下限) とする。
- 「計測のコマンド」は、リポジトリのルートで動かすと、計測した値を一つの数として標準出力の最後の行に出すコマンドを、インラインのコードで書く。
- 「ADR」の列には、決めた ADR と番号 (`ADR NNNN A1` など) を書く。
- ぶれる指標の計測のコマンドは、同じ実行の中で何回か測り、その中央値か 95 パーセンタイルを出す。
- この形は、CI で予算違反を見つけるスクリプト (dotfiles の `bin/budget-check`。dotfiles の docs/adr/0128) が読む。

予算を決めるのは ADR である。
ADR の受けいれ条件に予算を書いたら、同じ変更で予算の一覧にも書く。
予算の一覧だけを変えてはいけない。
正とする ADR は、`superseded [...]` をたどった最新の ADR である。
予算の一覧と ADR が食い違うときは、監査でその食い違いも指摘にし、直すときは予算の一覧を ADR に合わせる。

## CI で予算を確かめる

予算は、頼まれた監査のほかに、CI でも毎回、機械的に確かめる。
そのときは、dotfiles の `bin/budget-check` を使う (dotfiles の docs/adr/0128)。

- `bin/budget-check` は、予算の一覧の予算を計測して確かめ、違反を予算ごとに一つの issue (ラベル `budget-violation`、題 `予算違反: <名前> (<リポジトリのルートから見た一覧のパス>)`) にまとめる。
- 同じ予算の issue があるときは、前の記録が無いとき、満たした後にまた違反したとき、前の違反より悪いときだけコメントを足す。予算を満たしたときは、一度だけ知らせ、issue は閉じない。
- `--dry-run` は書き込みをせずにすることを出し、`--fail-on-violation` は、エラーの予算が無く違反があると終了コード 2 で終わる (エラーの予算があれば 1)。
- `--measure-to <結果のファイル>` は計測だけを行い、`gh` を呼ばない。`--report-from <結果のファイル>` は、結果のファイルから issue に書き込むだけで、計測のコマンドを動かさない (dotfiles の docs/adr/0132)。

CI では、計測と書き込みを別のジョブに分け、計測のジョブにはトークンを渡さない。
計測のコマンドは、リポジトリのビルドやベンチマークを動かすので、依存のパッケージのコードも動く。
同じジョブにトークンがあると、侵された依存のパッケージがそのトークンを使えるためである。
そのため、CI では、計測と書き込みを一つのプロセスで行う形 (オプションを付けない形) を使わない。
計測のジョブのチェックアウトには `persist-credentials: false` を付ける (付けないと、git の設定にトークンが残る)。

各リポジトリの CI には、そのリポジトリの ADR で、次のようなジョブを足す。
どのイベントで動かすかは、各リポジトリの ADR で決める。
fork からの `pull_request` では、トークンで issue に書き込めず、書き込みのジョブが終了コード 1 で終わる。
そのため、例では既定のブランチへの `push` で動かす。

```yaml
on:
  push:
    branches: [main]
jobs:
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
この例が各リポジトリで通るか (権限、artifact の受け渡し) は、各リポジトリに足すときに、そのリポジトリの ADR で動かして確かめる。

dotfiles の `bin/budget-check` を直したときは、各リポジトリの `ref` を上げる。

## 使う場面

本人がこの監査を頼んだときに使う。
リリースの前など、決まった時期の監査を頼まれたときも含む。
本人が「監査」とだけ頼んだときは、`security-audit` と `conformance-audit` の二つとも行う。
予算を決める前と変える前にも読む (予算の一覧の書き方を持つため)。

## 実行のしかた

監査は `auditor` に任せる。
Claude Code の `auditor` は Fable、Codex の `auditor` は `gpt-6-astra` で、推論の強さはモデルの既定である。
本人がプロンプトで推論の強さを指示したときだけ、それに従う。
`auditor` はコードもファイルも変えず、読んで動かして確かめる。
`auditor` に頼むときは、自分がどの推論の強さで動いているかも報告させる (記録の頭に書くため)。

監査の初めに、読むコミット (`git rev-parse HEAD`) と、範囲 (リポジトリ全体か、ある版からの差分か) を決める。

### auditor が変えなかったことの確かめ

`auditor` の「変えない」は指示だけで、設定では強制できない。
そのため、任せる側が、監査の前後で作業ツリーを比べる (dotfiles の docs/adr/0143)。

1. 任せる前に、監査するリポジトリで次の五つの出力を控える。
   - `git status --porcelain=v1 --untracked-files=all`
   - `git rev-parse HEAD`
   - `git stash list`
   - `git diff HEAD --binary | shasum`
   - `git ls-files -o --exclude-standard -z | xargs -0 shasum`

   後の二つは、監査の前から変わっていたファイルや追跡していないファイルを、`auditor` がさらに書き換えたことを見つけるためである。
2. `auditor` が返った後に、同じ五つを取り直して比べる。
3. 違っていれば、監査の記録とは別に、変わったパスと違いを本人に知らせる。直したり戻したりはしない。

Codex で監査するときは、`codex --sandbox read-only` で始めたセッションから `auditor` に任せる。
Codex の役割は、親のセッションの sandbox を引き継ぐためである。
このセッションでは記録を書けないので、監査の記録は、監査の後に、書き込める通常のセッションで書く。

## 指摘の形

指摘ごとに、観点、重大度 (高、中、低)、根拠、何が問題かを書く。
根拠には、`file:line`、動かしたコマンドと出力の要る部分、ADR の該当箇所と番号を書く。
確かめられなかったことは「未確認」として分ける。

## 記録

対象のリポジトリに `docs/audits/` があるとき、または本人が記録を求めたときは、監査の結果を `docs/audits/<YYYY-MM-DD>-conformance-audit.md` に書く。
ディレクトリが無いときは作る。
置き場所は、標準の docs の構成 (dotfiles の docs/adr/0129) に従う。

- 記録を書くのはメインのモデルである。
- メインのモデルは、頭に日付、読んだコミット、範囲、使ったモデル、指定した推論の強さ (指定が無ければ「指定なし」) と、`auditor` に報告させた推論の強さを書く。
- その後に、`auditor` が返した指摘を変えずに貼る。指摘を要約し直したり、言い換えたりしない。
- 頭の項目の後に、監査の前後で作業ツリーが変わらなかったか、変わったかを一行で書く。
- 記録はコミットした後に変えない。直したことや追加の監査は、新しい記録に書く。
- 記録を書かないときは、同じ形で本人にチャットで返す。

## 直すこと

監査は報告までで止める。
直すのは、本人が求めたときである。
仕様や振る舞いを変える直しは、ADR を作ってから行う。
