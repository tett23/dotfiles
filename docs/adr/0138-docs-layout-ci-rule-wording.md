# ADR 0138: docs/ の構成の CI の決まりを、今の共通の指示の文に決め直す

Status: proposed

## 文脈

[ADR 0129](0129-standard-docs-layout.md) は、共通の指示 (`.claude/CLAUDE.md`、`codex/AGENTS.md`) に「docs/ の構成」の節を置き、CI でビルドとテストを省く決まりと、「GitHub actions」の節の改め方を、文で決めた。
ところが、実装のコミット `7811057` で共通の指示に書いた文は、その ADR の文と一部が違う。
2026-11-16 の ADR 違反の監査 ([docs/audits/2026-11-16-conformance-audit.md](../audits/2026-11-16-conformance-audit.md) の指摘 8) は、これを受けいれ条件 A1 の「一字も違わずに」に合わないおそれとして挙げた。
本人は、ADR を作って扱うと決めた。

共通の指示の今の文は、ADR の文の意味を保ったうえで、モノレポの場合と、ビルドやテストの入力になる文書の場合をはっきりさせている。
そのため、この ADR で、今の共通の指示の文を正として決め直す。

## 調査した事項

- [ADR 0129](0129-standard-docs-layout.md) の「実装すること」の「標準の構成」の決まりの 3 つめは、「表のパスの中だけの変更では、ビルドとテストを省く。ただし、`docs/budgets.md` の変更では、予算の確かめ (…) を省かない。…文書の検査と、ADR と記録の変更不可の検査は省かない」である。同じ項は、「GitHub actions」の節の一文を「標準の構成の `docs/` のパス (`docs/budgets.md` を除く) の中だけの変更では省く。ほかの `docs/` のファイルは、ビルドやテストの入力になるかで判断する」に改めるとした。
- 今の `.claude/CLAUDE.md` の 53 行は、「表のパス (モノレポの `docs/<module name>/` の下のものを含む) の中だけの変更では、CI のビルドとテストを省く。ただし、ビルドやテストの入力になるファイルの変更では省かない。`docs/budgets.md` の変更では、予算の確かめ (`bin/budget-check`) を省かない。…」である。
- 今の `.claude/CLAUDE.md` の 130 行は、「標準の構成の `docs/` のパスの中だけの変更は、「docs/ の構成」の決まりに従う。ほかの `docs/` のファイルは、ビルドやテストの入力になるかで判断する (docs/adr/0129)」である。
- `codex/AGENTS.md` の 53 行と 131 行は、`.claude/CLAUDE.md` と同じ文である。両ファイルの「docs/ の構成」の節と「GitHub actions」の節を切り出して `cmp` すると、どちらも同じである。
- この文は、`git log -S'ビルドやテストの入力になるファイルの変更では省かない' -- .claude/CLAUDE.md codex/AGENTS.md` によると、[ADR 0129](0129-standard-docs-layout.md) の実装のコミット `7811057` で入った。
- ADR の文と今の文の違いは、次の 7 つである (`sed -n 55,56p docs/adr/0129-standard-docs-layout.md` と `sed -n '53p;130p' .claude/CLAUDE.md` を比べた)。
  - 表のパスに、モノレポの `docs/<module name>/` の下のものを含めると書いた。ADR の 2 つめの決まり (モノレポでは、`docs/<module name>/` に表と同じ構成を置ける) と合わせたものである。
  - 「ただし、ビルドやテストの入力になるファイルの変更では省かない」を足した。表のパスのファイル (`docs/budgets.md` など) がビルドやテストの入力になるときに、省かないためである。
  - 「GitHub actions」の節は、`docs/budgets.md` を除くことを書き直さず、「docs/ の構成」の決まりに従うとした。二つの節に同じ決まりを書くと、食い違いうるためである。
  - 「ビルドとテスト」を「CI のビルドとテスト」にした。
  - 「予算の確かめ ([ADR 0128](0128-budget-check-in-ci.md) の `bin/budget-check`)」を「予算の確かめ (`bin/budget-check`)」にした。
  - 「[ADR 0128](0128-budget-check-in-ci.md) のとおり、」を消した。
  - 「GitHub actions」の節の文の末尾に「(docs/adr/0129)」を足した。

## 実装すること

- 共通の指示の「docs/ の構成」の CI の決まりと、「GitHub actions」の節の文は、今の文のままとする。文書は変えない。
- [ADR 0129](0129-standard-docs-layout.md) のステータスを、`superseded [{"part":"実装すること (標準の構成: 表のパスの中だけの変更でビルドとテストを省く決まり)","by":["docs/adr/0138-docs-layout-ci-rule-wording.md"]},{"part":"実装すること (標準の構成: 「GitHub actions」の節の改め方)","by":["docs/adr/0138-docs-layout-ci-rule-wording.md"]},{"part":"受けいれ条件 (A1)","by":[],"kind":"note","note":"一字も違わずには両ファイルの節どうしの一致と読み、ADR の文との一致とは読まない"}]` にする。

## 実装しないこと

- 共通の指示の文を、[ADR 0129](0129-standard-docs-layout.md) の文に戻すこと。
- [ADR 0129](0129-standard-docs-layout.md) の受けいれ条件 A1 を変えること。A1 の確かめ方 (両ファイルの節を `diff` する) では、今の文でも差分が無い。

## 不変条件

なし。文書の文を決め直すだけの ADR である。

## 受けいれ条件

- A1: `.claude/CLAUDE.md` と `codex/AGENTS.md` の「docs/ の構成」の節と「GitHub actions」の節が、それぞれ同じで、上の調査の文を持つ。
- A2: [ADR 0129](0129-standard-docs-layout.md) のステータスが、上の `superseded` になっている。

## テスト設計

文書の変更なので、自動のテストは書かない。次で確かめる。

- A1: 両ファイルから二つの節を切り出して `cmp` し、`rg -n 'ビルドやテストの入力になるファイルの変更では省かない' .claude/CLAUDE.md codex/AGENTS.md` を動かす。
- A2: `adr-guard trace docs/adr/0129-standard-docs-layout.md` を動かす。

## トレードオフ

- 実装で文を変えたことを、後から ADR で追認する。ADR が先に決めるという決まりの順序とは逆である。

## 参考文献

- dotfiles の [ADR 0129](0129-standard-docs-layout.md)
- [docs/audits/2026-11-16-conformance-audit.md](../audits/2026-11-16-conformance-audit.md)
