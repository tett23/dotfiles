# ADR 0066: CI の adr-guard を 0.8.0 に上げ、記録・リンク・ステータスの行も検査する

ステータス: 採択

## 文脈

adr-guard は手元 (mise の `latest`) で 0.8.0 になった。0.8.0 では次のことが変わった。

- 監査や計測の記録 (`docs/audit/`・`docs/benchmarks/`) も、コミット済みのものは変更できない (`--allow-status`・`--allow-links` は効かない)。
- ステータスの行は、行頭が `ステータス:` か `Status:` の行だけ (`- Status:` は認めない)。`check-status` で、各 ADR に
  ちょうど 1 つあるかを検査できる。
- `links` で、文書の中のリンクの無い ADR の参照を検査できる。
- 意図した書き換えは、pre-commit では環境変数 `ADR_GUARD_ALLOW=<理由>`、CI (`check-range`) ではコミットのメッセージの
  トレーラー `ADR-Guard-Allow: <理由>` で許可できる。

これに合わせて、次のコミットを adr-guard を迂回して作った (本人の許可による。どちらもトレーラー `ADR-Guard-Allow` を付けた)。

- `7e8cde9`: [ADR 0001](0001-curl-sh-install.md)〜[0025](0025-send-to-kindle-single-file.md) の `- Status:` の行を `Status:` に書き換えた (値は変えない)。
- `e1a94c3`: 監査レポート 7 件の ADR の参照をリンクにした。

一方、CI の `adr` ジョブは `tett23/adr-guard@v0.1.0` のままで、次の問題がある。

- `allow-status`・`allow-links` を付けていないので、ステータスの行やリンクだけを変えたコミット ([ADR 0064](0064-adr-guard-allow-options.md) で
  手元の hook では許している変更) で失敗する。
- 記録の保護・`links`・`check-status`・トレーラーによる許可が無い (v0.1.0 に無い機能)。

adr-guard の action (`tett23/adr-guard@v0.8.0`) の入力は、`base`・`head`・`version`・`allow-status`・`allow-links`・`links`・`check-status`
(`links` と `check-status` は既定で有効)。手元で、master の作業ツリーの `adr-guard links`・`check-status` がどちらも違反 0、
上の 2 つのコミットの `check-range --allow-status --allow-links` が成功することを確かめた。

また、`docs/specifications.md` の「[ADR 0001](0001-curl-sh-install.md)〜0025 は `- Status:` の書き方のため、ステータスを更新しない」は、上の書き換えで古くなった。

## 実装すること

- `.github/workflows/ci.yml` の `adr` ジョブを `tett23/adr-guard@v0.8.0` にし、`allow-status: true`・`allow-links: true` を付ける
  (`links`・`check-status` は既定どおり有効)。
- `docs/specifications.md` を直す。
  - CI の節: adr-guard が、コミット済みの ADR・記録の変更、リンクの無い ADR の参照、ステータスの行の数を検査することを書く。
  - ADR の運用の節: 記録 (`docs/audit/`・`docs/benchmarks/`) もコミット後に変更できないこと、ステータスの行は `ステータス:` か `Status:`
    で始まる行であること、意図した書き換えは `ADR_GUARD_ALLOW` (pre-commit) とトレーラー `ADR-Guard-Allow` (CI) で許可することを書く。
    [ADR 0001](0001-curl-sh-install.md)〜0025 の `- Status:` の記述は、`Status:` に書き換えたことに改める。

## 実装しないこと

- action の版を `latest` などで追うこと (GitHub Actions は版のタグで参照する。上げるときは CI の設定を直す)。
- 手元の hook (`.githooks/pre-commit`・`.claude/settings.json`) の変更 (0.8.0 でもそのまま使える)。
- [ADR 0001](0001-curl-sh-install.md)〜0025 のステータスの値の書き方 (`Accepted → 0031` など) を今の形 (`採択→…は[ADR NNNN](…)`) に揃えること。

## テスト設計

- CI の設定の変更のため、自動テストは書かない。次を確かめる。
  - `.github/workflows/ci.yml` が YAML として読め、`adr` ジョブの `uses` と `with` が上のとおりであること。
  - 手元で、action と同じ検査 (`adr-guard check-range --allow-status --allow-links <push の前の origin/master> HEAD`・`adr-guard links`・
    `adr-guard check-status`) が成功すること。
  - push の後に、GitHub Actions の `adr` ジョブが成功すること。

## トレードオフ

- CI が `links`・`check-status` も検査するので、リンクの無い ADR の参照を含む文書をコミットすると CI が失敗する (pre-commit も同じ検査をする)。
- 手元の adr-guard (mise の `latest`) と CI (v0.8.0 に固定) の版がずれることがある。adr-guard が上がったら、CI の版も上げる。
