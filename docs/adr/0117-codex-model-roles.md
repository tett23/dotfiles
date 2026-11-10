# ADR 0117: Codex でも、作業の種類ごとにモデルを使い分ける

ステータス: 採択

## 文脈

[ADR 0114](0114-codex-agents-md.md) は、`codex/AGENTS.md` から `.claude/CLAUDE.md` の「モデルの使い分け」の節を除き、Codex のモデルの使い分けを書かないことにした。
本人から、Codex のモデルを Claude におおむね対応させ、その記述を足すよう頼まれた。

Claude Code の側では、既定のモデルを Opus とし、次の作業をモデルを固定したサブエージェントに任せている ([ADR 0111](0111-claude-agents-in-dotfiles.md))。

| エージェント | モデル | 任せる作業 |
| --- | --- | --- |
| `auditor` | Fable | ADR と実装・テストの乖離の調査、セキュリティ監査、本人が明示して頼んだ作業 |
| `reader` | Sonnet | 外部のリポジトリや長いログを読む、確かめのスクリプト、機械的な実装 |
| `runner` | Haiku | テストや確かめを動かして数える、検索、CI の確認 |

調べたことは次のとおり。

- Codex (`codex-cli 0.166.0`) のモデルの一覧 (`~/.codex/models_cache.json`) のうち、今の世代のものは次のとおり。説明は一覧のまま。

  | モデル | 説明 | 推論の強さ (`model_reasoning_effort`) |
  | --- | --- | --- |
  | `gpt-6-astra` | Frontier intelligence for the most demanding work. | low〜ultra |
  | `gpt-6-sol` | Previous generation workhorse model. | low〜ultra |
  | `gpt-6-luna` | Fast and affordable model for easier tasks. | low〜max |
  | `gpt-reserve` | Fast and affordable agentic coding model. | low〜max |

- 今の `~/.codex/config.toml` は、`model = "gpt-6-astra"`・`model_reasoning_effort = "low"` である。`config.toml` は dotfiles で管理しない ([ADR 0114](0114-codex-agents-md.md))。
- Codex は、サブエージェントの役割 (agent role) を、設定のフォルダーの `agents/` (`~/.codex/agents/`) の TOML のファイルから読む
  (openai/codex `rust-v0.166.0` の `codex-rs/agent-roles/src/loader.rs`)。
  ファイルは `name`・`description`・`nickname_candidates` を持ち、残りのキーはその役割の設定として `config.toml` の値を上書きする
  (`codex-rs/agent-roles/src/agent_role_config.rs`)。したがって、役割ごとに `model`・`model_reasoning_effort`・`developer_instructions` を書ける。
- Codex のサブエージェントは、`spawn_agent` のツールで起動する (実行ファイルの中の説明「Spawns an agent to work on the specified task.」)。

## 実装すること

- `codex/agents/` に、Claude Code のエージェントに対応する 3 つの役割のファイルを置く。`developer_instructions` には、`.claude/agents/` の各ファイルの本文と同じことを書く。

  | ファイル | `name` | `model` | `model_reasoning_effort` | 対応する Claude Code のエージェント |
  | --- | --- | --- | --- | --- |
  | `auditor.toml` | `auditor` | `gpt-6-astra` | `xhigh` | `auditor` (Fable) |
  | `reader.toml` | `reader` | `gpt-6-sol` | `medium` | `reader` (Sonnet) |
  | `runner.toml` | `runner` | `gpt-6-luna` | `low` | `runner` (Haiku) |

- `flake.nix` の `home.file` に `".codex/agents".source = link "codex/agents";` を足す。
- `codex/AGENTS.md` に「モデルの使い分け」の節を足す。`.claude/CLAUDE.md` の同じ節を、次のように Codex 向けにする。
  - 既定のモデルは `gpt-6-astra` とする (Claude の Opus に当たる)。ADR、設計の判断、本人への報告は既定のモデルで行う。
  - 「Fable に任せる」「Sonnet に任せる」「Haiku に任せる」を、それぞれ `auditor` (`gpt-6-astra`、`xhigh`)・`reader` (`gpt-6-sol`)・`runner` (`gpt-6-luna`) に任せる、とする。項目の中身は同じにする。
  - 「任せるときの決まり」は同じにする。「Fable の調査や監査の結果は、Opus が要約し直さずに」は、「`auditor` の結果は、要約し直さずに」とする。
- `docs/specifications.md` のリンクの表と Codex の記述に書く。README は変えない。

## 実装しないこと

- `~/.codex/config.toml` の既定のモデルを変えること。今の値 (`gpt-6-astra`) が、この ADR の既定と同じである。
- `gpt-reserve` を使うこと。`gpt-6-luna` と同じく速く安いモデルで、Haiku に当たるものは一つで足りる。
- `.claude/CLAUDE.md` を変えること。

## テスト設計

設定の変更なので、CI の自動テストは書かない。実装の後に次を確かめる。

- 3 つの TOML のファイルを `taplo check` か、TOML として読めるかで確かめる。
- `nix flake check --no-build` が通る。
- 本人が `sudo darwin-rebuild switch --flake ~/dotfiles#dione` を実行した後、`~/.codex/agents` が dotfiles の `codex/agents` を指すリンクになる。
- `codex exec` で、`runner` の役割のサブエージェントに `pwd` を動かして結果を返すよう頼み、その役割で起動したことが出力に出る。起動の警告 (「Ignoring malformed agent role definition」など) が出ない。

## 結果

- 3 つの役割のファイルは、`nix eval` の `builtins.fromTOML` で読めた (`name`・`model`・`model_reasoning_effort` が表のとおり)。`taplo` は入っていないので、こちらで確かめた。
- `codex/AGENTS.md` に「モデルの使い分け」の節を足した。`.claude/CLAUDE.md` との差分は、既定のモデルの文、役割の置き場所、3 つの見出し、`auditor` を明示して頼む項目、要約し直さない項目だけである。
- `nix flake check --no-build` は通った。
- switch を待たずに `ln -s ~/dotfiles/codex/agents ~/.codex/agents` でリンクを作った (switch のときに home-manager が `agents.hm-backup` に退かし、自分のリンクに置きかえる)。
- `codex exec` で `runner` の役割のサブエージェントに `pwd` を頼むと、`/Users/tett23/dotfiles — runner` と答えた。起動の警告は出なかった。サブエージェントが `gpt-6-luna` で動いたことは確かめていない。

## トレードオフ

- Codex のモデルの名前は、Claude のモデルと一対一には対応しない。`auditor` は既定と同じ `gpt-6-astra` で、推論の強さだけを上げる。
- モデルの名前を固定するので、Codex のモデルの世代が変わると、役割のファイルを書きかえる。
- `codex/AGENTS.md` と `.claude/CLAUDE.md` の「モデルの使い分け」は、言いかえがあるので手で合わせる ([ADR 0114](0114-codex-agents-md.md) と同じ)。

## 参考文献

- openai/codex のタグ `rust-v0.166.0` の `codex-rs/agent-roles/src/loader.rs`、`codex-rs/agent-roles/src/agent_role_config.rs`
- `~/.codex/models_cache.json`
- dotfiles の `.claude/agents/`、`codex/AGENTS.md`、[ADR 0111](0111-claude-agents-in-dotfiles.md)、[ADR 0114](0114-codex-agents-md.md)
