# ADR 0118: CLAUDE.md と AGENTS.md の、ときどきしか使わない節をスキルに分ける

ステータス: 採択

## 文脈

本人から、トークンの使用量を減らすため、全リポジトリ共通の指示のうち適当なところをスキルに分ける ADR を作るよう頼まれた。
また、本人の指示で `.claude/CLAUDE.md` と `codex/AGENTS.md` に「ADR を書いた後は、`close-reading` スキルで精読する」と足した (全リポジトリ共通の指示の変更は、これまでも ADR にしていない)。そこで、`close-reading` を全リポジトリと Codex で使えるようにするよう頼まれた。

`.claude/CLAUDE.md` (Claude Code) と `codex/AGENTS.md` (Codex。[ADR 0114](0114-codex-agents-md.md)) は、すべてのセッションの毎ターンの文脈に入る。
`.claude/CLAUDE.md` は、コミット `575d3f3` の時点で 13829 バイト、この ADR を書いた時点の作業ツリー (「不変条件」の決まりと `close-reading` の一文を足した後) で 14469 バイトある。
いちばん大きい節は「ADR」(約 69 行) だが、本人の指示で残す (「実装しないこと」)。スキルに移す節と消す節の行数 (見出しを除く) は次のとおり。

| 節 | 行数 | 使う場面 |
| --- | --- | --- |
| 「文書の書き方」 | 23 | 文書を書くとき |
| 「タグとリリース」 | 6 | リリースするとき |
| 「モデルの使い分け」の「Fable に任せる」「Sonnet に任せる」「Haiku に任せる」 | 24 | サブエージェントに任せるとき |

調べたことは次のとおり。

- Claude Code のスキルは、普段は名前と説明だけが文脈に入り、使うときに本文 (`SKILL.md`) が読み込まれる。全リポジトリ共通のスキルは `~/.claude/skills/<名前>/` に置く。
- Codex (`codex-cli 0.166.0`) のスキルも、普段は名前・説明・パスの一覧だけが文脈に入り、使うと決めたときに `SKILL.md` を読む
  (openai/codex `rust-v0.166.0` の `codex-rs/ext/skills/src/catalog_prompt.rs` 24〜28 行)。
  全リポジトリ共通のスキルは `~/.agents/skills/<名前>/` に置く (`~/.codex/skills` は非推奨。`codex-rs/ext/skills/src/host_roots.rs` 135〜146 行)。
  `SKILL.md` は `name`・`description` の前付けを持つ (`codex-rs/skills/src/parser.rs`)。ユーザーのスキルのディレクトリの symlink はたどる (`codex-rs/ext/skills/src/loader/host.rs` 165 行)。
- `~/.claude/skills/` と `~/.agents/skills/` は普通のディレクトリで、dotfiles で管理していないスキル (`close-reading`・`find-skills`・`grill-me` など) がある。
  `~/.claude/skills/find-skills` と `~/.claude/skills/grill-me` は、`~/.agents/skills/` の同じ名前のディレクトリへの symlink で、一つのスキルを両方から使っている。
- `close-reading` は `~/.claude/skills/close-reading/` (`SKILL.md` 468 行、`research.md` 117 行) にある普通のディレクトリで、dotfiles で管理していない。
  Golem のために書いたもので、拠りどころの文書の表などが Golem のディレクトリ (`manual/`・`modules/`・`docs/roadmap.md` など) を名指ししている。`~/.agents/skills/` には無いので、Codex からは使えない。
- 「モデルの使い分け」の 3 つの節の項目は、Claude Code のエージェントの `description` ([ADR 0111](0111-claude-agents-in-dotfiles.md)) と Codex の役割の `description` ([ADR 0117](0117-codex-model-roles.md)) にも書いてある。
  エージェントの一覧は、その `description` とともに毎ターンの文脈に入る。

## 実装すること

- dotfiles に `agents/skills/` を作り、次の 3 つのスキルを置く。中身は Claude Code と Codex の両方で使えるように書く。

  | スキル | 移す節 | `description` (使う場面) |
  | --- | --- | --- |
  | `doc-writing` | 「文書の書き方」 | README、仕様書、ADR、マニュアルなどの文書を書く・直すとき |
  | `release` | 「タグとリリース」 | タグを打つとき、リリースノートや CHANGELOG を書くとき |
  | `close-reading` | 今の `~/.claude/skills/close-reading/` の `SKILL.md` と `research.md` を、Golem に特有の文書の名指しを「リポジトリにある文書を最初に確かめる」手順に置きかえて写す。ADR の構成の並びには「不変条件」を足す。手順、約束、報告の形は弱めない | 精読、校閲、文書のレビュー、ADR を書いた後と採択する前 |

- `flake.nix` の `home.file` で、各スキルのディレクトリを `~/.claude/skills/<名前>` と `~/.agents/skills/<名前>` の両方にリンクする。dotfiles で管理していないスキルがあるので、ディレクトリ全体はリンクしない。
  今の `~/.claude/skills/close-reading/` は、switch のときに home-manager が `close-reading.hm-backup` に退かすと見込む (ファイルで退かした先例は [ADR 0114](0114-codex-agents-md.md) にあるが、ディレクトリの場合は未確認。テスト設計で確かめる)。
- `.claude/CLAUDE.md` と `codex/AGENTS.md`:
  - 移した節を消し、代わりに一行で、そのスキルを使う場面と、使う前にスキルを読むことを書く (例: 「文書を書く・直す前に、`doc-writing` スキルを読む」)。
  - 「モデルの使い分け」の 3 つの節を消し、既定のモデルと「任せるときの決まり」だけを残す。どの作業をどのエージェント (役割) に任せるかは、エージェントの `description` に任せる。
    節の頭の「次の作業は、モデルを固定したサブエージェント…に任せる」の文は、「どの作業をどのエージェントに任せるかは、各エージェントの説明 (`description`) に従う」に書きかえる。
- `docs/specifications.md` のリンクの表と Claude Code・Codex の記述に書く。README は変えない。

## 実装しないこと

- 「ADR」の節 (テンプレート、adr-guard の入れ方、未実装の ADR の実装を含む) をスキルに移すこと。ADR の決まりは必ず守らせたいので、毎ターンの文脈に残す (本人の指示)。
- 言語ごとの決まり (Rust・TypeScript・Python)、「ツール」、「GitHub actions」、外部のリポジトリの節をスキルに移すこと。どれも短く、作業の途中で気づかずに破りやすい。
- dotfiles で管理していないほかのスキル (`find-skills`・`grill-me` など) を dotfiles に入れること。
- Bash の出力の上限を設定すること。別の ADR にする。

## 不変条件

なし。指示の文をファイルの間で移す手順と、リンクの設定だけを決める ADR で、入力に対する振る舞いを決めない。

## テスト設計

設定の変更なので、CI の自動テストは書かない。実装の前と後に、次を確かめる。

- `wc -c .claude/CLAUDE.md codex/AGENTS.md` のバイト数を、実装を始める直前の作業ツリーと実装の後で比べる。
- 移した節の文が、スキルの `SKILL.md` に一字も落ちずにあることを、移す前の節と `diff` で確かめる (見出しの深さと、スキルの前付けを除く)。
- `close-reading` の新しい `SKILL.md` と元の `SKILL.md` の差分を読み、変えたのが Golem に特有の文書の名指しと、その代わりの手順だけであることを確かめる。`grep -i golem` が何も出さない。
- `close-reading` の `research.md` も、元と `diff` して、変えたのが Golem に特有の名指しだけであることを確かめる。
- 新しい `close-reading` で、ADR 0118 と [ADR 0119](0119-claude-bash-output-limit.md) を精読し、重大度が高の指摘が残らない (残った指摘は直してからレビューに出す)。
- `nix flake check --no-build` が通る。
- 本人が `sudo darwin-rebuild switch --flake ~/dotfiles#dione` を実行した後:
  - `~/.claude/skills/<名前>` と `~/.agents/skills/<名前>` が、dotfiles の `agents/skills/<名前>` を指すリンクになる。
  - `~/.claude/skills/close-reading.hm-backup` に、元のディレクトリが残る。
  - Claude Code の新しいセッションで、スキルの一覧に `doc-writing`・`release`・`close-reading` が出る。「リリースノートの項目の分け方を答えて」と頼むと、`release` スキルを読んで答える。
  - `codex exec` で、使えるスキルの一覧に `doc-writing`・`release`・`close-reading` が出る。同じくリリースノートの項目の分け方を頼むと、`release` スキルを読んで答える。
- 「ADR」の節の内容が、`.claude/CLAUDE.md` と `codex/AGENTS.md` に残り、一字も変わらないことを、実装の前の節と `diff` で確かめる。
- `.claude/CLAUDE.md` と `codex/AGENTS.md` の差分が、[ADR 0114](0114-codex-agents-md.md)・[ADR 0117](0117-codex-model-roles.md) で決めたところだけであることを、`diff` で確かめる。

## 結果

- `agents/skills/doc-writing/SKILL.md` と `agents/skills/release/SKILL.md` を作った。本文は、移す前の節と `diff` して、末尾の改行のほかは一字も変わらなかった。
- `.claude/CLAUDE.md` は 14469 バイトから 10162 バイトに、`codex/AGENTS.md` は 14730 バイトから 10311 バイトになった (約 30% 減)。
- `.claude/CLAUDE.md` と `codex/AGENTS.md` の差分は、出力の言語の主語、hook の設定の場所、`/goal`、Python の一行、既定のモデルの 2 文、調べものの 2 項目、要約し直さない項目だけだった ([ADR 0114](0114-codex-agents-md.md)・[ADR 0117](0117-codex-model-roles.md) で決めたところ)。「ADR」の節は変えていない。
- `close-reading` は、Golem の名指しを置きかえた版を `agents/skills/close-reading/` に置いた (`grep -i golem` は 0 件)。この版で ADR 0118 と [ADR 0119](0119-claude-bash-output-limit.md) を精読し、高 1 件 ([ADR 0119](0119-claude-bash-output-limit.md))、中 4 件、低 8 件の指摘を直してからレビューに出した。
- `nix flake check --no-build` は通った。switch の後の確かめ (リンク、`.hm-backup`、スキルの一覧) は、本人が switch した後に行う。

## トレードオフ

- スキルの本文は、使うと判断されたときにしか読まれない。判断を誤ると、文書の書き方やリリースの決まりを読まずに書くことがある。CLAUDE.md と AGENTS.md に「使う前にスキルを読む」と書いて減らすが、なくせはしない。
- スキルを使うターンは、`SKILL.md` を読む分だけ、今より多くトークンを使う。使わないターンが多いので、全体では減る。
- 「モデルの使い分け」の 3 つの節を消すので、どの作業をどのエージェントに任せるかの判断は、エージェントの `description` だけに頼る。

## 参考文献

- openai/codex のタグ `rust-v0.166.0` の `codex-rs/ext/skills/src/catalog_prompt.rs`、`codex-rs/ext/skills/src/host_roots.rs`、`codex-rs/skills/src/parser.rs`、`codex-rs/ext/skills/src/loader/host.rs`
- Claude Code のドキュメント「Skills」(https://code.claude.com/docs/en/skills)
- dotfiles の `.claude/CLAUDE.md`、`codex/AGENTS.md`、[ADR 0111](0111-claude-agents-in-dotfiles.md)、[ADR 0114](0114-codex-agents-md.md)、[ADR 0117](0117-codex-model-roles.md)
