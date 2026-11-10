# ADR 0111: Claude Code のサブエージェントの定義を dotfiles で管理する

ステータス: 採択

## 文脈

全リポジトリ共通の指示 `.claude/CLAUDE.md` に「モデルの使い分け」の節を足した。この節で、作業の種類ごとに Fable・Sonnet・Haiku のサブエージェントへ任せることにした。
CLAUDE.md の指示に頼るだけでは、Agent ツールの `model` を毎回正しく指定するとは限らない。そこで、モデルを固定したエージェントの定義を置くよう、本人から頼まれた。

調べたことは次のとおり。

- Claude Code は、`~/.claude/agents/*.md` を全リポジトリ共通のエージェントとして、`<リポジトリ>/.claude/agents/*.md` をそのリポジトリのエージェントとして読む。
  定義の前付けに、`name`・`description`・`model`・`tools` を書く。
- `~/.claude/agents/` は今は無い (`ls ~/.claude/agents` は `No such file or directory`)。
- `flake.nix` の `home.file` は、`.claude/settings.json` と `.claude/CLAUDE.md` を `link` (`mkOutOfStoreSymlink`) で dotfiles の実体にリンクしている ([ADR 0015](0015-fix-breaking-audit-items.md))。
  Claude Code の設定のリンク元は `.claude/` にまとめてある ([ADR 0030](0030-claude-config-in-dot-claude.md))。

## 実装すること

- `.claude/agents/` に次の 3 つの定義を置く。本文には、返す形 (動かしたコマンド、数値、`file:line`) と、日本語で書くことを書く。

  | ファイル | `model` | `tools` | 任せる作業 |
  | --- | --- | --- | --- |
  | `auditor.md` | `fable` | `Read, Grep, Glob, Bash` | ADR と実装・テストの乖離の調査、セキュリティ監査、本人が Fable を明示して頼んだ作業。コードを変えない |
  | `reader.md` | `sonnet` | `Read, Grep, Glob, Bash, Edit, Write` | 外部のリポジトリのソースや長いログを読む、確かめのスクラッチのスクリプト、採択された ADR とテストがそろった機械的な実装 |
  | `runner.md` | `haiku` | `Bash, Read, Grep, Glob` | テストや lint、確かめのスクリプトを動かして数える、`rg` での検索、`nix search`・`mise registry`、`gh` での CI の確認。コードを変えない |

- `flake.nix` の `home.file` に `".claude/agents".source = link ".claude/agents";` を足す。
- `.claude/CLAUDE.md` の「モデルの使い分け」に、この 3 つのエージェントの名前を書く。
- `docs/specifications.md` のリンクの表と Claude Code の記述に書く。README は Claude Code の設定の一覧を持たないので変えない。

## 実装しないこと

- エージェントごとの `effort` などの細かい設定。使ってみてから考える。
- `auditor` と `runner` の書き換えを、`tools` から Bash を外して防ぐこと。Bash が無いとテストや確かめのコマンドを動かせないので、本文の指示で防ぐ。

## テスト設計

設定の変更なので、CI の自動テストは書かない。実装の後に次を確かめる。

- 本人が `sudo darwin-rebuild switch --flake ~/dotfiles#dione` を実行した後、`~/.claude/agents` が dotfiles の `.claude/agents` へのリンクになる。
- `claude agents` の一覧に、`auditor`・`reader`・`runner` が、それぞれのモデルとともに出る。
- dotfiles 以外のリポジトリのセッションで、3 つのエージェントを呼べる (Agent ツールの一覧に出る)。

## 結果

- 実装の前、`~/.claude/agents` は無かった (`ls ~/.claude/agents` は `No such file or directory`)。
- `nix flake check --no-build` は通った (`darwinConfigurations.dione`)。
- 「テスト設計」の `claude agents` は、エージェントの定義でなく、動いているセッションの一覧を出すコマンドだった (`claude agents --json` で確かめた)。この確かめは使えない。
- 代わりに `claude -p --model haiku` で新しいセッションを開き、エージェントの一覧を尋ねようとしたが、`Failed to authenticate: OAuth session expired and could not be refreshed` で動かなかった。
- 本人が確かめる: `darwin-rebuild switch` の後、`~/.claude/agents` が dotfiles の `.claude/agents` へのリンクになることと、dotfiles 以外のリポジトリの新しいセッションで `/agents` の一覧に `auditor`・`reader`・`runner` がそれぞれのモデルで出ること。

## トレードオフ

- dotfiles の `.claude/agents/` は、dotfiles のリポジトリのエージェントとしても読まれる。dotfiles のセッションでは、同じ定義がリポジトリと全体の両方から読まれる。中身が同じなので動きは変わらない。
- `auditor` と `runner` は、Bash でファイルを書き換えられる。書き換えないことは本文の指示に頼る。
- `model` の名前 (`fable`・`sonnet`・`haiku`) は別名なので、Claude Code が指す版を上げると、使われるモデルも変わる。

## 参考文献

- Claude Code のドキュメント「Subagents」(https://docs.claude.com/en/docs/claude-code/sub-agents)
- dotfiles の `flake.nix`、[ADR 0015](0015-fix-breaking-audit-items.md)、[ADR 0030](0030-claude-config-in-dot-claude.md)
