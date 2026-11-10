# ADR 0114: Codex の全体の指示 AGENTS.md を CLAUDE.md に沿って作り、dotfiles で管理する

ステータス: 採択

## 文脈

本人から、`AGENTS.md` を `CLAUDE.md` の内容に沿って作り、シンボリックリンクにするよう頼まれた。Claude Code に特有のところは、Codex 向けに直す。

調べたことは次のとおり。

- Codex は `codex-cli 0.166.0` で、`flake.nix` の `home.packages` で入れている (`dependencies.md` の `codex-cli`)。
- Codex は、`~/.codex/AGENTS.md` を全リポジトリ共通の指示として読む。今の `~/.codex/AGENTS.md` は普通のファイルで (101 バイト、2026-11-06)、中身は次の一行だけである。

  > ファイルにPythonを書き出し禁止。AIがツールとして使うぶんには問題ない。

- 全リポジトリ共通の Claude Code の指示は `.claude/CLAUDE.md` で、`~/.claude/CLAUDE.md` にリンクしている ([ADR 0030](0030-claude-config-in-dot-claude.md))。
- `.claude/CLAUDE.md` のうち、Claude Code に特有のところは次のとおり。
  - 「原則」の「Claude Codeの出力は日本語で書く」。
  - 「ADR」の「Claude Code の hook は全体の設定 (`~/.claude/settings.json`) で有効なので不要」。adr-guard には Claude Code 用の `claude-hook` があるが、Codex 用の hook は無い
    (`tett23/adr-guard` を ghq で取得したものを `rg -il codex` で探して、該当なし)。
  - 「未実装ADRの自動実装」の `/goal`。Claude Code のコマンドである。
  - 「モデルの使い分け」の節すべて。Claude のモデル (Opus・Fable・Sonnet・Haiku) と、`~/.claude/agents/` のサブエージェント ([ADR 0111](0111-claude-agents-in-dotfiles.md)) を使う。
- 「Python」の節は、Python のスクリプトをコミットしないとする。今の `~/.codex/AGENTS.md` は、それより強く、ファイルに Python を書き出すこと自体を禁じている。

## 実装すること

- `codex/AGENTS.md` を作る。中身は `.claude/CLAUDE.md` と同じにし、次のところだけを Codex 向けに変える。

  | `.claude/CLAUDE.md` | `codex/AGENTS.md` |
  | --- | --- |
  | 「Claude Codeの出力は日本語で書く」 | 「Codexの出力は日本語で書く」 |
  | 「Claude Code の hook は全体の設定 (`~/.claude/settings.json`) で有効なので不要」 | 「Codex には adr-guard の hook が無い。コミットした ADR の本文 (ステータスの行を除く) を書きかえないことは、pre-commit hook と CI の `adr` ジョブが止める」 |
  | 「基本的に `/goal` ですべての採択（未実装）ADRを実装します」 | 「採択（未実装）ADR を実装するよう頼まれたときの、デフォルトの指示は以下」 |
  | 「モデルの使い分け」の節 | 書かない |
  | 「Python」の節 | 今の `~/.codex/AGENTS.md` の「ファイルに Python を書き出さない。ツールとして使うのはよい」を足す |

- `codex/AGENTS.md` の先頭に、`.claude/CLAUDE.md` から作ったことと、変えるときは両方を同じく変えることを、HTML の注釈で書く。`.claude/CLAUDE.md` の先頭にも同じ注釈を書く。
- `flake.nix` の `home.file` に `".codex/AGENTS.md".source = link "codex/AGENTS.md";` を足す。今の `~/.codex/AGENTS.md` は、switch のときに home-manager が `AGENTS.md.hm-backup` に退かす。
- `docs/specifications.md` のリンクの表と Claude Code の節に書く。README は変えない。

## 実装しないこと

- `.claude/CLAUDE.md` から `codex/AGENTS.md` をスクリプトで生成すること。変えるところが少なく、文の言いかえもあるので、手で合わせる。
- `~/.codex/config.toml` を dotfiles で管理すること。Codex が自分で書く状態が混ざる。
- Codex の hook (`hooks.json`) で adr-guard を動かすこと。adr-guard に Codex 用の hook が無い。
- Codex のモデルやサブエージェントの使い分けを書くこと。

## テスト設計

設定の変更なので、CI の自動テストは書かない。実装の後に次を確かめる。

- `diff .claude/CLAUDE.md codex/AGENTS.md` の差分が、「実装すること」の表のところと、先頭の注釈だけである。
- 本人が `sudo darwin-rebuild switch --flake ~/dotfiles#dione` を実行した後:
  - `ls -l ~/.codex/AGENTS.md` が、dotfiles の `codex/AGENTS.md` を指すリンクになる。
  - `~/.codex/AGENTS.md.hm-backup` に、今の一行の中身が残る。
  - Codex の新しいセッションで、出力が日本語になり、ADR の決まりを答えられる (例: 「ADR はどこに置き、いつコミットするか」と尋ねる)。

## 結果

- `codex/AGENTS.md` を作った。`diff .claude/CLAUDE.md codex/AGENTS.md` の差分は、先頭の注釈、出力の言語の主語、adr-guard の hook の文、`/goal` の文、「モデルの使い分け」の節 (39 行) を除いたことと、Python の一行を足したことだけだった。`codex/AGENTS.md` に `Claude` の語が残るのは、先頭の注釈だけである。
- `nix flake check --no-build` は通った。
- 本人が `darwin-rebuild switch` を実行した後の確かめ (「テスト設計」の残り) は、まだ行っていない。

## トレードオフ

- 同じ内容の 2 つのファイルを手で合わせるので、片方だけを変えると食い違う。先頭の注釈で知らせるが、検査はしない。
- Codex には adr-guard の hook が無いので、コミットした ADR を書きかえようとしても、コミットするまで止まらない。

## 参考文献

- Codex の `AGENTS.md` の扱い: `codex-cli 0.166.0` の実行ファイルに含まれる指示 (「The scope of an AGENTS.md file is the entire directory tree rooted at the folder that contains it.」など)
- `tett23/adr-guard` (ghq で取得)
- dotfiles の `.claude/CLAUDE.md`、`flake.nix`、[ADR 0030](0030-claude-config-in-dot-claude.md)、[ADR 0111](0111-claude-agents-in-dotfiles.md)
