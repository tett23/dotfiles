---
name: adr
description: ADR (docs/adr/) の決まり。採択の記録、修正と破棄、adr-guard の入れ方、ファイルの置き場所と名前、テンプレート、不変条件の書き方、精読、未実装の ADR の実装。ADR を書く・直す・採択する・実装する・破棄するとき、リポジトリに adr-guard を入れるとき、未実装の ADR をまとめて実装するときに使う。これらの前に必ず読む。
---

# ADR（docs/adr/）

採択されたら、まず `Status: proposed` のまま ADR をコミットし、次のコミットでステータスを `accepted` (実装済み) か `accepted-pending` (未実装) に変える。adr-guard は、追加の時点で `accepted` の ADR と、決まりにない状態の遷移を拒否する。
仕様を変更したくなった場合は、新たに修正用のADRを作成する。元のADRを書きかえてはいけない。
修正用の ADR が採択されたら、元の ADR のステータスを `superseded [{"part":null,"by":["docs/adr/NNNN-....md"]}]` にする。一部だけを変えたときは、`part` にその部分の名前 (節の名前など) を書く。`adr-guard trace` で修正の連なりをたどれる。
ADRを破棄する場合は、ステータスを `discarded` にして、理由をdocs/specifications.mdに記述する。

変更を不可にする方法は以下にある。リポジトリを初期化するときにはREADMEに従うこと。
https://github.com/tett23/adr-guard

具体的には、次の 3 つを行う。Claude Code と Codex の hook は全体の設定 (`~/.claude/settings.json`、`~/.codex/hooks.json`) で有効なので不要。

1. `.githooks/pre-commit` を置き、実行権限を付ける。ほかの検査と並べる場合は、`exec` の行を最後に置く。

   ```sh
   #!/bin/sh
   exec adr-guard pre-commit --allow-status --allow-links
   ```

2. clone ごとに `git config core.hooksPath .githooks` を実行する (README にも手順を書く)。
3. CI に adr-guard の `adr` ジョブを足す (adr-guard の README の例のとおり)。

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

ADR作成後とドキュメント更新後は `adr-guard links --fix` でADRのリンクをチェックし、修正する。

ADR を書いた後は、本人のレビューに出す前に、`close-reading` スキルで ADR を精読し、指摘を直す。

## 未実装ADRの自動実装

`accepted-pending` の ADR を実装するとき (Claude Code では `/goal` で頼まれるとき) の、デフォルトの指示は以下。

```
ADRを全て読み、ステータスが accepted-pending で現状実装可能なものを全て実装。実装が止まりそうなときはその場所を後回しにしてもよい。実装はADRごとにpull-reqを作成する。CIが通ればpull-reqはマージコミットでマージしてよい。停止後、どこを後回しにしたかのレポートをチャットに出力すること。実装のpull-reqには実装が終わったものはステータスを accepted にする変更を含める。
```
