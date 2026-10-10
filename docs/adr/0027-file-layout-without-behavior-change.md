# ADR 0027: ファイル配置の監査のうち、挙動を変えないもの (L7, L9, L12) を是正する

ステータス: 採択

## 文脈

ファイル配置の監査 (`docs/audit/2026-10-09-file-layout.md`) の未対応項目のうち、直してもリンク先や読み込み順が
変わらないものは次の 3 つ。

- **L7** ルート直下に単独のファイル (`bat-config`、`gitconfig`、`gitignore_global`、`rubocop.yml`) があり、
  `ghostty/config` や `mise/config.toml` のようにツール名のディレクトリに置くものと揃っていない。
- **L9** テストの置き場所と実行方法がツールごとに違い (zsh は `zsh/tests/`、usage-hint mod は `claude/mods/usage-hint/tests/`、
  send-to-kindle は本体の中)、まとめて書かれた場所が無い。
- **L12** リポジトリ直下に `.gitignore` が無く、`.DS_Store`・`.ruby-lsp/`・`.claude/settings.local.json` を
  本人の global ignore (`gitignore_global`) に頼っている。別の環境で clone すると追跡対象に見える。

## 実装すること

- **L7** リポジトリ内の場所だけを、リンク先 (`~/.config/<ツール>/…` の形) に揃える。リンク先は変えない。

  | 移動前 | 移動後 | リンク先 (変えない) |
  |---|---|---|
  | `bat-config` | `bat/config` | `~/.config/bat/config` |
  | `gitconfig` | `git/config` | `~/.gitconfig` |
  | `gitignore_global` | `git/ignore` | `~/.gitignore_global` |
  | `rubocop.yml` | `rubocop/config.yml` | `~/.rubocop.yml` |

  - `git mv` で移し、`flake.nix` のリンク元のパスと `docs/specifications.md` の配置の表を直す。
- **L9** README に「テスト」の節を足し、テストの置き場所と実行コマンドをまとめる。置き場所は統一しない
  (send-to-kindle は 1 ファイルである必要がある。ADR 0025)。
- **L12** リポジトリ直下に `.gitignore` を置き、このリポジトリで出るもの (`.DS_Store`、`.ruby-lsp/`、
  `.claude/settings.local.json`) を書く。

## 実装しないこと

- リンク先を XDG の場所 (`~/.config/git/config` など) に移すこと (L3〜L6。挙動が変わる)。
- `karabiner/.gitignore` の統合 (Karabiner-Elements 用の除外で、ディレクトリ内にあるほうが分かりやすい)。
- テストの置き場所の統一と、usage-hint mod のテストの CI への追加。

## テスト設計

- 設定ファイルとドキュメントの変更のため、自動テストは書かない。
- `nix eval --raw .#darwinConfigurations.dione.system.drvPath` が通ることを確かめる (CI の nix-eval と同じ)。
- `git check-ignore` で、`.gitignore` の各項目がリポジトリの `.gitignore` によって無視されることを確かめる。
- `sudo darwin-rebuild switch` の後、`~/.gitconfig`・`~/.gitignore_global`・`~/.rubocop.yml`・`~/.config/bat/config` が
  移動後のファイルを指し、`git config user.name` と `bat --config-file` が従来どおり読めることを確かめる。

## トレードオフ

- 移動してから `darwin-rebuild switch` を実行するまでの間、`~/.gitconfig` などのリンクは移動前のパスを指したまま切れる。
  この間は git の `user.name` などが読めない。pull した他のマシンでも、`darwin-rebuild switch` を実行するまで同じ状態になる。
  移動と `darwin-rebuild switch` は続けて行う。
- `.gitignore` の項目は global ignore と重複する。
