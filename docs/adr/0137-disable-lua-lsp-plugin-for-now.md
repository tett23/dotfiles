# ADR 0137: Claude Code のプラグイン lua-lsp を、直るまで無効にする

Status: proposed

## 文脈

[ADR 0116](0116-remove-example-skills-plugin.md) は、`.claude/settings.json` の `enabledPlugins` で有効にするプラグインを `lua-lsp@claude-plugins-official` だけにすると決めた。
その「実装しないこと」には、「`lua-lsp` を外すこと。nvim の設定 (Lua) を書くときに使う」とある。
`docs/specifications.md` の Claude Code の節も、有効にするプラグインは `lua-lsp` だけと書いている。

ところが、今の `.claude/settings.json` では、`lua-lsp@claude-plugins-official` が `false` である。
2026-11-16 の ADR 違反の監査 ([docs/audits/2026-11-16-conformance-audit.md](../audits/2026-11-16-conformance-audit.md) の指摘 4) は、これを ADR と仕様書に合わない違反として挙げた。

本人によると、`false` にしたのは、`lua-lsp` がメモリをリークするためである。
本人は、新しい nvim がリリースされればリークは直ると見ていて、それまで無効にしておく。
そのため、この ADR で、`lua-lsp` を直るまで無効にすることを決め、[ADR 0116](0116-remove-example-skills-plugin.md) と仕様書をそれに合わせる。

## 調査した事項

- `jq -c .enabledPlugins .claude/settings.json` は `{"lua-lsp@claude-plugins-official":false}` を出す。有効なプラグインは無い。
- `true` を `false` に変えたのは、コミット `2f84621` (2026-11-10。`Reorder the Claude Code settings as the app writes them`) である (`git show 2f84621 -- .claude/settings.json`)。コミットのメッセージは、無効にした理由を書いていない。
- `docs/specifications.md` の 269 行は「有効にするプラグインは `lua-lsp` だけにする」と書いている。
- メモリのリークと、新しい nvim で直ることは、本人の説明であり、この ADR では確かめていない。

## 実装すること

- `.claude/settings.json` の `"lua-lsp@claude-plugins-official": false` を、今のまま残す。プラグインの項目は消さない。有効にし直すときに、値を `true` にするだけで済むためである。
- `docs/specifications.md` の Claude Code の節の「有効にするプラグインは `lua-lsp` だけにする」を、「`lua-lsp` は、メモリをリークするので、直るまで無効にしている (`enabledPlugins` で `false`)。ほかのプラグインは有効にしない」に直し、この ADR へのリンクを添える。
- `docs/roadmap.md` が無いので作り、「新しい nvim がリリースされてリークが直ったら、新しい ADR で `lua-lsp` を有効にし直す」項目を置く。書き方は `roadmap` スキルに従う。
- [ADR 0116](0116-remove-example-skills-plugin.md) のステータスを、`superseded [{"part":"実装すること (有効にするプラグインは lua-lsp だけ)","by":["docs/adr/0137-disable-lua-lsp-plugin-for-now.md"]},{"part":"実装しないこと (lua-lsp を外すこと)","by":["docs/adr/0137-disable-lua-lsp-plugin-for-now.md"],"kind":"supplement"}]` にする。

## 実装しないこと

- `lua-lsp` を `enabledPlugins` から消すこと。直ったら有効にし直すので、項目を残す。
- リークを調べること、直ったかを自動で確かめること。有効にし直す時期は、本人が決める。
- 有効にし直すことを、この ADR で決めること。有効にし直すときは、この ADR を `superseded` にする新しい ADR を書き、その ADR で設定、仕様書、ロードマップを直す。この ADR の受けいれ条件 A1 は、そのときに置き換わる。

## 不変条件

なし。設定の値と文書だけを決める ADR である。

## 受けいれ条件

- A1: `jq -c .enabledPlugins .claude/settings.json` が `{"lua-lsp@claude-plugins-official":false}` を出す。
- A2: `docs/specifications.md` が `lua-lsp` を無効にしている理由とこの ADR へのリンクを書き、`docs/roadmap.md` に有効にし直す項目がある。
- A3: [ADR 0116](0116-remove-example-skills-plugin.md) のステータスが、上の `superseded` になっている。

## テスト設計

設定と文書の変更なので、自動のテストは書かない。実装の後に、次で確かめる。

- A1: `jq -c .enabledPlugins .claude/settings.json`。
- A2: `rg -n lua-lsp docs/specifications.md docs/roadmap.md` と `rg -n 'adr/0137' docs/specifications.md`。
- A3: `adr-guard trace docs/adr/0116-remove-example-skills-plugin.md`。

## トレードオフ

- 無効のあいだ、Claude Code は nvim の Lua の設定を書くときに LSP の診断を使えない。
- 有効にし直す時期を、ロードマップの項目と本人の判断に頼る。

## 参考文献

- dotfiles の [ADR 0116](0116-remove-example-skills-plugin.md)
- [docs/audits/2026-11-16-conformance-audit.md](../audits/2026-11-16-conformance-audit.md)
