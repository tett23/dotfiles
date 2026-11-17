# ADR 0141: CI の action を lockfile でコミットに固定し、Nix のインストーラーのハッシュを確かめる

Status: accepted-pending

## 文脈

2026-11-16 のセキュリティの監査 ([docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md) の指摘 6) は、次の二つを重大度「低」の問題として挙げた。

- `.github/workflows/ci.yml` の action を、タグ (`actions/checkout@v7` など) で指していて、コミットで固定していない。タグを動かされると、別の中身が CI で動く。
- `bootstrap.sh` は、版を固定した URL の Nix のインストーラーを `curl | sh` で動かすが、そのハッシュを確かめない。

本人は、ADR を作って扱うと決めた。
本人は、版を固定すると Dependabot などの更新の仕組みが要り、運用が重くなるのを嫌う ([ADR 0134](0134-mise-lockfile-checksums.md) で、mise を `latest` のままにした)。
そのため、action は、タグのまま書き、別の lockfile でコミットを記録する形を選ぶ。

## 調査した事項

- `ci.yml` の `uses:` は 6 か所である。`actions/checkout@v7` が 26、39、57、74 行、`tett23/adr-guard@v0.13.1` が 63 行、`DeterminateSystems/determinate-nix-action@v3` が 76 行である (`grep -n 'uses:' .github/workflows/*.yml`)。
- 2026-11-17 に `gh api repos/<owner>/<repo>/commits/<tag> --jq .sha` で読んだタグの指すコミットは、`actions/checkout@v7` が `3d3c42e5aac5ba805825da76410c181273ba90b1`、`DeterminateSystems/determinate-nix-action@v3` が `16f94ba7aae399b9f9077c254b6719ec6de7e3e3`、`tett23/adr-guard@v0.13.1` が `ab55769152ed0f8a3465ee3435a2df43ab9d067f` である。
- GitHub は、2025-08-15 から、リポジトリと組織の設定で、フルの SHA で固定していない action を拒めるようにした ([GitHub の changelog](https://github.blog/changelog/2025-08-15-github-actions-policy-now-supports-blocking-and-sha-pinning-actions/))。GitHub の文書は、フルの SHA で固定することを、action を変わらないものとして使う唯一の方法としている ([Secure use reference](https://docs.github.com/en/actions/reference/security/secure-use))。
- GitHub は、2026-10-14 に、workflow の依存の lockfile (`.github/workflows/actions.lock`) を public preview にした ([GitHub の changelog](https://github.blog/changelog/2026-10-14-github-actions-workflow-lockfiles-in-public-preview/))。InfoQ は、2026-10-28 に GA になったと報じた ([InfoQ](https://infoq.com/news/2026/11/github-actions-lockfiles-ga))。
  - changelog と InfoQ は、使えるプランを「GitHub Enterprise Cloud、Enterprise Cloud with data residency、Team、Free」と書く。個人のアカウントの Free と Pro のリポジトリで使えるかは、書いていない (確かめていない)。
  - workflow はタグのまま書き、lockfile が各参照の解決したコミットを記録する。Actions は、記録したコミットを動かすので、タグが動いても動くものは変わらない (同じ changelog)。
  - 「Require lockfile」の設定で、lockfile を使うことを強制できる。これも public preview である (同じ changelog)。
- lockfile は、GitHub CLI の拡張 `gh actions-lock` (`github/gh-actions-lock`) が作る。README (2026-11-05 のコミット `90ae563`) は、次のモードを挙げる。
  - `gh actions-lock`: lockfile を作る、直す。
  - `gh actions-lock --relock`: 動いた参照 (`v4` など) を、今の上流のコミットに進める。
  - `gh actions-lock --verify`: CI で、lockfile が今の状態と合うかを確かめる。
  - `gh actions-lock --verify-local`: pre-commit 向けに、すべての `uses:` に lockfile の項目があるかだけを確かめる。
  - 制限として、ほかのリポジトリの reusable workflow と、コンテナのイメージは固定しない。
- `bootstrap.sh` は、`curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix/tag/v3.24.1 | sh -s -- install --no-confirm` で Nix を入れる (57〜58 行)。
- 2026-11-17 に、この URL を二度取ると、二度とも同じ 571 行のスクリプト (`sha256` が `1470fa510a9e3e8d8e03c7dc50f89c22003a0d7077a43486b6a3e97e3dde6160`) だった。スクリプトは、`NIX_INSTALLER_BINARY_ROOT` の既定を同じ版の URL として、そこから本体を取る (33 行)。スクリプトの中に、取った本体のハッシュを確かめる処理があるかは、確かめていない (`grep -i sha256` で、それらしい行は見つからなかった)。
- `README.md` の 6 行は、dotfiles の `install.sh` を `HEAD` から `curl | sh` で動かす手順である。
- `gh extension install` は、`--pin` で拡張をリリースのタグかコミットに固定できる (`gh extension install --help`)。
- `bootstrap.sh` の最後は、条件の無い `main "$@"` である。インストーラーの版の固定は、[ADR 0046](0046-fix-audit-non-breaking.md) で決めた (`bootstrap.sh` の 56 行の注釈)。

## 実装すること

- `gh actions-lock` で `.github/workflows/actions.lock` を作り、コミットする。`ci.yml` の `uses:` は、タグのまま変えない。
- `gh-actions-lock` の README の `.github/workflows/verify-lockfile.yml` を写して直し、別の workflow のファイルとして置く。この workflow は、`gh actions-lock --verify` で lockfile が今の workflow と合うかを確かめる。この workflow も lockfile に入れる。`ci.yml` は変えない。
- その workflow で拡張を入れるときは、`gh extension install github/gh-actions-lock --pin <タグ>` で版を固定する。タグは、実装のときの最新のリリースにする。
- action の版を上げるとき (タグが動いたとき、新しいメジャー版にするとき) は、`gh actions-lock --relock` か、`uses:` を直した後の `gh actions-lock` で lockfile を更新し、その差分をコミットする。この手順を `docs/specifications.md` の CI の項に書く。Dependabot は入れない。
- リポジトリの設定の「Require lockfile」を有効にする。設定は GitHub の側にあるので、本人が行う。
- `bootstrap.sh` の最後の `main "$@"` を、直に動かされたときだけ呼ぶ形にする (`source` したときは関数の定義だけを行う。`bin/sync-deps` と同じ形)。テストから `ensure_nix` を呼ぶためである。
- `bootstrap.sh` は、インストーラーを一時ファイルに取り、`shasum -a 256` の値が、スクリプトに書いた値 (今は `1470fa51…6160`) と一致するときだけ `sh` で動かす。一致しなければ、エラーを出して終了コード 1 で終わる。版を上げるときは、URL とハッシュを一緒に書き換える。`bootstrap.sh` は Nix の前に動くので、macOS に最初からある `shasum` と `curl` だけを使う。
- `docs/specifications.md` の「インストール」の節の、`bootstrap.sh` の手順 (22〜23 行) に、インストーラーのハッシュを確かめることを書く。
- [ADR 0046](0046-fix-audit-non-breaking.md) のステータスを、`superseded [{"part":"N4 (Nix のインストーラーの版の固定)","by":["docs/adr/0141-ci-actions-lockfile-and-installer-hash.md"],"kind":"supplement"}]` にする。

## 実装しないこと

- `ci.yml` の `uses:` を SHA に書き換えること。lockfile で同じ効果を得て、タグのまま読めるようにする。
- Dependabot や Renovate を入れること (本人の方針)。
- Nix のインストーラーが取る本体のハッシュを、別に確かめること。
- `README.md` の `install.sh` を `HEAD` から取る手順を変えること。dotfiles そのものを信じる起点なので、ハッシュを置く場所が無い。
- ほかのリポジトリの CI に lockfile を入れること。それぞれのリポジトリの ADR で行う。

## 不変条件

- I1: `bootstrap.sh` の Nix の導入は、取ったインストーラーの `sha256` が書いた値と違うとき、インストーラーを動かさず、終了コード 1 で終わる。
- I2: `bootstrap.sh` の Nix の導入は、`sha256` が一致するとき、インストーラーを `install --no-confirm` の引数で一度だけ動かす。

lockfile の振る舞いは GitHub が決めるので、不変条件にしない。

境界の入力:

| 入力 | 期待 | 不変条件 |
| --- | --- | --- |
| 偽の `curl` が、決めたハッシュと違う中身を返す | インストーラーを動かさず 1 | I1 |
| 偽の `curl` が、空のファイルを返す | インストーラーを動かさず 1 | I1 |
| 偽の `curl` が失敗する | インストーラーを動かさず 1 | I1 |
| 偽の `curl` が、決めたハッシュの中身を返す | 一度だけ動かす | I2 |

## 受けいれ条件

- A1: `.github/workflows/actions.lock` がコミットされ、CI の lockfile の確かめのステップが通る。
- A2: `zsh/tests/bootstrap.test.zsh` の、上の不変条件の番号を持つテストが通る。
- A3: 本人が、リポジトリの設定で「Require lockfile」を有効にし、その後の CI が通る。
- A4: dotfiles の CI の shellcheck のジョブが通る。

## テスト設計

- A1: push した後の CI の結果で確かめる。個人のアカウントのリポジトリで lockfile が使えないときは、この ADR を進めず、action を SHA で固定する別の ADR を書く。
- A2: `bootstrap.sh` を `source` して `ensure_nix` を呼ぶ。偽の `curl` と、インストーラーの代わりに引数を記録する偽の中身で、境界の入力の表の行をテストにする。テストを先に書いて失敗させる。テストの名前は `ADR 0141 I1: …` の形にする。
- A3: 本人が設定した後の CI の結果で確かめる。

## トレードオフ

- action の版を上げるたびに、`gh actions-lock` を動かす手間が増える。Dependabot は入れないので、上げる時期は本人が決める。
- lockfile の機能は新しく、使えるプランと振る舞いが変わりうる。
- インストーラーのハッシュを確かめても、インストーラーが取る本体は確かめない。
- lockfile の確かめのために、gh の拡張という依存が CI に一つ増える。版は `--pin` で固定し、上げるときは本人が書き換える。

## 参考文献

- [docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md)
- dotfiles の [ADR 0134](0134-mise-lockfile-checksums.md)
- https://github.blog/changelog/2025-08-15-github-actions-policy-now-supports-blocking-and-sha-pinning-actions/
- https://docs.github.com/en/actions/reference/security/secure-use
- https://github.blog/changelog/2026-10-14-github-actions-workflow-lockfiles-in-public-preview/
- https://infoq.com/news/2026/11/github-actions-lockfiles-ga
- https://github.com/github/gh-actions-lock
