# ADR 0116: Claude Code のプラグイン example-skills を外す

ステータス: 採択

## 文脈

本人から、トークンを減らすため、使っていないスキルを外すよう頼まれた。スキルの説明は、すべてのセッションの毎ターンの文脈に入る。

`.claude/settings.json` の `enabledPlugins` で有効にしているのは、`lua-lsp@claude-plugins-official` と `example-skills@anthropic-agent-skills` の 2 つである。
`example-skills` のために、`extraKnownMarketplaces` に `anthropic-agent-skills` (`anthropics/skills`) を足している。ほかに `anthropic-agent-skills` を使うプラグインは無い。

`example-skills` が持ち込むスキルと、使うかどうかは次のとおり。

| スキル | 用途 | 使うか |
| --- | --- | --- |
| `algorithmic-art`・`canvas-design`・`slack-gif-creator`・`theme-factory`・`brand-guidelines` | 画像、GIF、ブランドの作業 | 使わない |
| `internal-comms`・`doc-coauthoring` | 社内向けの文書、文書の共同執筆 | 使わない |
| `web-artifacts-builder`・`frontend-design`・`webapp-testing` | Web の UI の作業 | 使わない |
| `mcp-builder` | MCP サーバーを作る | 使わない |
| `skill-creator` | スキルを作る | Claude のアプリが入れる `anthropic-skills:skill-creator` と同じ名前で重なる |

[ADR 0046](0046-fix-audit-non-breaking.md) の C4 で、`skill-creator@claude-plugins-official` を外し、`example-skills` の中の `skill-creator` を使うことにした。
今は、Claude のアプリが `anthropic-skills:skill-creator` を入れているので、`example-skills` を外しても `skill-creator` は残る。

## 実装すること

- `.claude/settings.json` の `enabledPlugins` から `example-skills@anthropic-agent-skills` を外す。
- `.claude/settings.json` の `extraKnownMarketplaces` から `anthropic-agent-skills` を外す。空になれば、キーごと消す。
- `docs/specifications.md` の Claude Code の節に、有効にするプラグインは `lua-lsp` だけであることを書く。README は変えない。

## 実装しないこと

- Claude のアプリやアカウントの側で入るプラグイン (`engineering`・`cowork-plugin-management`・`anthropic-skills`) を外すこと。dotfiles の設定では無いので、本人がアプリの設定で外す。
- `lua-lsp` を外すこと。nvim の設定 (Lua) を書くときに使う。

## テスト設計

設定の変更なので、CI の自動テストは書かない。実装の前と後に、次を確かめる。

- `jq '.enabledPlugins, .extraKnownMarketplaces' .claude/settings.json` で、実装の後は `example-skills` と `anthropic-agent-skills` が無い。
- 実装の後に開いた新しいセッションで、使えるスキルの一覧に `example-skills:` で始まるスキルが無く、`anthropic-skills:skill-creator` が有る (本人が新しいセッションで尋ねて確かめる)。

## 結果

- 実装の前: `enabledPlugins` は `lua-lsp@claude-plugins-official` と `example-skills@anthropic-agent-skills`、`extraKnownMarketplaces` は `anthropic-agent-skills`。
- 実装の後: `enabledPlugins` は `lua-lsp@claude-plugins-official` だけになり、`extraKnownMarketplaces` は空になったので、キーごと消した。
- 新しいセッションでスキルの一覧を確かめるのは、本人が行う (「テスト設計」)。

## トレードオフ

- `example-skills` のスキルを使いたくなったときは、`enabledPlugins` に戻す。
- `anthropic-skills:skill-creator` は Claude のアプリが入れるもので、dotfiles では管理できない。アプリの側で外れると、`skill-creator` は無くなる。

## 参考文献

- dotfiles の `.claude/settings.json`、[ADR 0046](0046-fix-audit-non-breaking.md)
- https://github.com/anthropics/skills
