# ADR 0144: 古いコミットのメールアドレスのために履歴を書き換えない

Status: proposed

## 文脈

dotfiles は公開のリポジトリである。
2026-11-16 のセキュリティの監査 ([docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md) の指摘 10) は、次の二つを重大度「低」の問題として挙げた。

- 履歴に、gmail のほかに、勤務先らしいドメインのメールアドレスが二つある。
- 消したファイル `open_gh.sh` (コミット `1d5f187` で消した) に、ほかの組織のリポジトリの名前が残る。

どちらも、公開の履歴から読める。
本人は、ADR を作って扱うと決めた。
そのため、この ADR で、履歴を書き換えるかを決める。

## 調査した事項

- `git log --all --format='%ae' | sort | uniq -c` の件数は、gmail のアドレスが 715 件、ほかの二つのアドレスが 13 件と 10 件である。二つのアドレスのコミットの期間は、13 件のものが 2014-08-20 から 2017-09-04、10 件のものが 2012-09-14 から 2013-06-27 である。監査が挙げた 26 件と 20 件は、author と committer を足した数と合う。
- `open_gh.sh` に残る、ほかの組織らしいリポジトリの参照は、1 種類、1 か所である。
- `.mailmap` は無い。
- GitHub の文書 ([Removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)) は、履歴を書き換えたときのことを次のように書く。
  - 書き換えると、その後のすべてのコミットのハッシュが変わり、ハッシュに頼る道具が壊れる。
  - fork にあるコミットは、そこで読めるままである。ほかの人の clone からは消せない。
  - GitHub の上のキャッシュされた表示では、SHA-1 のハッシュで直に読める。キャッシュを消すために GitHub Support が手伝うのは、秘密の情報 (sensitive data) のときだけである。
- dotfiles の master は、rebase を原則禁止にしている (共通の指示の「Git運用方針」)。履歴を書き換えると、`docs/adr/` と `docs/audits/` が引くコミットのハッシュ (`91e3814`、`2f84621` など) も変わる。
- `.mailmap` は、`git log` などの表示の名前とアドレスを変えるだけで、コミットの中のアドレスは変えない。

## 実装すること

- 履歴を書き換えない。二つのアドレスと、`open_gh.sh` の中のリポジトリの名前は、公開の履歴に残ることを受けいれる。
- `.mailmap` は置かない。表示だけを変えても、公開の履歴から読めることは変わらないためである。
- `docs/specifications.md` には書かない。振る舞いを変えないためである。

## 実装しないこと

- `git filter-repo` などで、履歴の author と committer のアドレスを書き換えること。上の調査のとおり、fork と clone とキャッシュには残り、コミットのハッシュがすべて変わる。
- GitHub Support に、キャッシュを消すよう頼むこと。古いメールアドレスは秘密の情報 (sensitive data) ではないと判断した。GitHub の文書の sensitive data の定義は引いていない。
- 今後のコミットのアドレスを決めること。今の設定のアドレスで作る。

## 不変条件

なし。何もしないことを決める ADR である。

## 受けいれ条件

- A1: master の履歴が書き換えられていない。監査の記録を入れたコミット `2c2dd2f` が、この ADR の後も `origin/master` の祖先である。

## テスト設計

自動のテストは書かない。

- A1: `git fetch` の後に、`git merge-base --is-ancestor 2c2dd2f origin/master` の終了コードが 0 であることを確かめる。

## トレードオフ

- 二つの古いアドレスと、ほかの組織のリポジトリの名前は、公開の履歴から読めるままである。
- 将来、秘密の情報が履歴に入ったときは、この ADR と別に、書き換えるかを決め直す。

## 参考文献

- [docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md)
- https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository
