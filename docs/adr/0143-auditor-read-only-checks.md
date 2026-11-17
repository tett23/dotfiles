# ADR 0143: auditor がファイルを変えなかったことを、任せる側が監査の前後で確かめる

Status: accepted

## 文脈

監査は、`auditor` のエージェントに任せる ([ADR 0126](0126-audit-skill.md))。
`auditor` の指示は「コードを変えず、読んで動かして確かめるだけにする」である ([ADR 0111](0111-claude-agents-in-dotfiles.md)、[ADR 0117](0117-codex-model-roles.md))。

2026-11-16 のセキュリティの監査 ([docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md) の指摘 9) は、これを重大度「低」の問題として挙げた。
「コードを変えない」は指示だけで、設定では強制されていない。
Claude Code の `auditor` は `Bash` を持ち、Codex の `auditor` の設定に sandbox の指定は無い。
本人は、ADR を作って扱うと決めた。

調べたところ、どちらの道具でも、`Bash` を残したまま書き込みだけを設定で確実に止める手段は無かった。
そのため、この ADR では、設定で止めることをあきらめ、任せる側が監査の前後で作業ツリーを比べ、変わっていれば本人に知らせることを決める。

## 調査した事項

- `.claude/agents/auditor.md` の frontmatter は、`model: fable` と `tools: Read, Grep, Glob, Bash` である (4〜5 行)。`Write` と `Edit` は持たない。
- `codex/agents/auditor.toml` は、`name`、`description`、`model`、`model_reasoning_effort`、`developer_instructions` を持ち、`sandbox_mode` を持たない。
- `.claude/settings.json` は、`sandbox.enabled: true` を持ち、`permissions` を持たない (`jq '{sandbox,permissions}' .claude/settings.json`)。
- Claude Code のサブエージェントの文書 (`https://code.claude.com/docs/en/sub-agents.md`。2026-11-17 に取った) は、次のように書く。
  - frontmatter は `tools`、`disallowedTools`、`permissionMode`、`hooks` などを持てる (223 行)。
  - `disallowedTools` に `Bash(git push *)` のように書いても、Bash そのものを外す。Bash を残してコマンドだけを止めるには、settings の `permissions.deny` に書き、その規則はメインの会話にも効く (301、508 行)。
  - メインの会話が `bypassPermissions`、`acceptEdits`、auto mode のとき、サブエージェントは同じモードで動き、`permissionMode` の指定は無視される (610 行)。
- Codex (openai/codex のコミット `36e074a2fb`、2026-11-10) は、役割の設定ファイルの `approval_policy` と `sandbox_mode` を使わず、親の値を引き継ぐ。`codex-rs/core/src/agent/role_tests.rs` のテストは、役割のファイルに `sandbox_mode = "danger-full-access"` を書いても、子の設定が親の `permissions` と同じであることを確かめる (role_tests.rs の 465〜560 行)。`codex-rs/core/src/agent/child_config.rs` の注釈も、役割は親と承認、cwd、sandbox を違えられないと書く (119、196 行)。Codex の文書は読んでいない。
- この ADR を書いた Claude Code のセッションは、auto mode で動いている (セッションの設定)。そのため、`permissionMode` で `auditor` を `plan` にしても、効かない場合がある。
- Claude Code の sandbox は、セッション全体の Bash に効き、作業ディレクトリ (`.`) への書き込みを許す (このセッションの sandbox の設定の `write.allowOnly`)。そのため、sandbox は、`auditor` がリポジトリの中を書き換えることを止めない。

## 実装すること

- `security-audit` と `conformance-audit` のスキル (`agents/skills/*/SKILL.md`) の、`auditor` に任せる手順に、次を足す。
  - 任せる前に、任せる側が、監査するリポジトリで次の五つの出力を控える。`git status --porcelain=v1 --untracked-files=all`、`git rev-parse HEAD`、`git stash list`、`git diff HEAD --binary | shasum`、`git ls-files -o --exclude-standard -z | xargs -0 shasum`。後の二つは、監査の前から変わっていたファイルや追跡していないファイルを、`auditor` がさらに書き換えたことを見つけるためである。
  - `auditor` が返った後に、同じ五つを取り直して比べる。違っていれば、監査の記録とは別に、変わったパスと違いを本人に知らせる。直したり戻したりはしない。
  - 監査の記録には、前後で変わらなかったか、変わったかを一行で書く。
- Codex で監査するときは、`codex --sandbox read-only` で始めたセッションから `auditor` に任せることを、同じスキルに書く。役割は親の sandbox を引き継ぐためである。監査の記録は、監査の後に、書き込める通常のセッションで書く。
- `docs/specifications.md` の Claude Code の節の監査の項目 (280 行) に、任せる側が前後で作業ツリーを比べることを書く。
- [ADR 0126](0126-audit-skill.md) のステータスに、`{"part":"実装すること (監査のスキルの手順)","by":["docs/adr/0143-auditor-read-only-checks.md"],"kind":"supplement"}` を足して、`superseded` にする。

## 実装しないこと

- Claude Code の settings の `permissions.deny` に、書き込みのコマンドを並べること。メインの会話にも効き、`git -C . push` のような書き方をすり抜けうる。
- `auditor` の frontmatter の `permissionMode` を `plan` にすること。メインの会話が auto mode のときは無視される。
- `auditor` の frontmatter の `hooks` で、Bash のコマンドを検査して止めること。書き込みのコマンドを漏れなく判定できない。
- `auditor` から `Bash` を外すこと。監査は、テストや確かめのコマンドを動かす。

## 不変条件

なし。任せる側の手順だけを決める ADR である。

## 受けいれ条件

- A1: 二つのスキルに、任せる前後で五つの出力を比べる手順と、Codex の `--sandbox read-only` のことが書いてある。
- A2: 次に監査を任せたときに、記録に、前後で作業ツリーが変わったかの一行がある。

## テスト設計

手順の変更なので、自動のテストは書かない。

- A1: スキルを読み、`close-reading` で精読して確かめる。
- A2: 次の監査の記録で確かめる。

## トレードオフ

- `auditor` が書き込むことは防げず、後から見つけるだけである。
- `git status` は、リポジトリの外 (ホームの設定など) への書き込みを見つけない。
- Codex で、本人が `--sandbox read-only` で始め忘れると、`auditor` は書き込める。
- Codex の `--sandbox read-only` のセッションでは、`auditor` は `$TMPDIR` に使い捨てのリポジトリを作って確かめることができず、任せる側も監査の記録を書けない。

## 参考文献

- dotfiles の [ADR 0111](0111-claude-agents-in-dotfiles.md)、[ADR 0117](0117-codex-model-roles.md)、[ADR 0126](0126-audit-skill.md)
- [docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md)
- https://code.claude.com/docs/en/sub-agents
- https://github.com/openai/codex (コミット `36e074a2fb`)
