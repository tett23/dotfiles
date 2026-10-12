# ADR 0030: Claude Code の設定と mod を `.claude/` にまとめる

ステータス: 採択

## 文脈

Claude Code の設定は、リポジトリ内の 2 か所に分かれていた (ファイル配置の監査の L2)。

| リポジトリ内 | 内容 | リンク先 |
|---|---|---|
| `claude/settings.json` | 本人の設定 (ステータスライン、プラグイン、テーマ、auto mode、`CLAUDE_CODE_PLUGIN_DIRS`) | `~/.claude/settings.json` |
| `claude/mods/usage-hint/` | 使用量を表示する mod ([ADR 0004](0004-usage-hint-mod.md)) | (リンクせず、`CLAUDE_CODE_PLUGIN_DIRS` で読み込む) |
| `.claude/CLAUDE.md` | 全リポジトリ共通の指示 | `~/.claude/CLAUDE.md` |
| `.claude/skills/sync-deps/` | dotfiles 用のスキル | (このリポジトリのプロジェクト設定) |

`~/.claude/` に入るもののリンク元が `claude/` と `.claude/` に分かれており、どちらに何があるのか分かりにくい。

## 実装すること

- `claude/` の中身をすべて `.claude/` に移し、`claude/` を無くす。

  | 移動前 | 移動後 |
  |---|---|
  | `claude/settings.json` | `.claude/settings.json` |
  | `claude/mods/usage-hint/` | `.claude/mods/usage-hint/` |

  - mod のファイルの中身は変えない。生成物の `.claude-plugin/types/` は従来どおり、その中の `.gitignore` で git の管理外にする。
- `.claude/settings.json` の `CLAUDE_CODE_PLUGIN_DIRS` を `~/dotfiles/.claude/mods/usage-hint` にする。
- `flake.nix` の `~/.claude/settings.json` のリンク元を `.claude/settings.json` にする。`~/.claude/CLAUDE.md` は従来どおり
  `.claude/CLAUDE.md` (並びを `settings.json` の隣に移す)。
- `docs/specifications.md` の配置の表と Claude Code の節、README のテストの表 (usage-hint の置き場所と実行コマンド) を直す。

## 実装しないこと

- 全リポジトリ共通の設定と、dotfiles 専用の設定の分離。`.claude/settings.json` と `.claude/CLAUDE.md` は、
  `~/.claude/` へのリンク元であると同時に、このリポジトリのプロジェクト設定としても読まれる (トレードオフを参照)。
- `.claude/settings.local.json` (このリポジトリ用の許可ルール。git の管理外) の整理。
- `~/.claude/skills/` (本人のスキル) を dotfiles で管理すること。

## テスト設計

- 設定ファイルの移動のため、自動テストは書かない。
- `nix eval --raw .#darwinConfigurations.dione.system.drvPath` が通ることを確かめる (CI の nix-eval と同じ)。
- 移動前の `claude/settings.json` と `.claude/settings.json` の違いが `CLAUDE_CODE_PLUGIN_DIRS` だけであることを確かめる。
- 移動前後で mod の各ファイルの中身が同じであることを確かめる。
- `sudo darwin-rebuild switch` の後、`~/.claude/settings.json` が `.claude/settings.json` を指していることを確かめる。
- `claude plugin test .claude/mods/usage-hint` が通ることを確かめる。
- Claude Code を起動し直し、ステータスラインと usage-hint の表示が従来どおり出ることを本人が確かめる。

## トレードオフ

- `.claude/settings.json` は、全リポジトリ共通の設定 (`~/.claude/settings.json`) であると同時に、このリポジトリでは
  プロジェクト設定としても読まれる。同じ内容なので値は変わらないが、プロジェクト設定にだけ書くべきもの
  (dotfiles 専用の許可ルールなど) を書く場所は `.claude/settings.local.json` しか無い。
- 移動してから `darwin-rebuild switch` を実行するまでの間、`~/.claude/settings.json` のリンクは移動前のパスを指したまま切れ、
  Claude Code の全体設定が読み込まれない。他のマシンで pull した後も同じ。
