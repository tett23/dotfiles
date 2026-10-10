# dotfiles の仕様

このリポジトリが現在どう動くかをまとめる。経緯と判断の理由は [docs/adr](adr) を参照。
ADR で仕様が変わったら、この文書と [README](../README.md) を同時に更新する。

## 対象

- macOS (Apple Silicon)。nix-darwin のホスト名は `dione`。
- 置き場所は `~/dotfiles` (環境変数 `DOTFILES`)。tmux・Claude Code の設定・`flake.nix` がこの場所を前提にしている。

## インストール

```sh
curl -fsSL https://raw.githubusercontent.com/tett23/dotfiles/HEAD/install.sh | sh
```

`install.sh` は冪等で、次を順に行う (ADR 0001)。失敗したら同じコマンドを再実行する。

1. Xcode Command Line Tools を入れる。
2. `~/dotfiles` に HTTPS で clone し、submodule を取得する。その後 `origin` を SSH の URL
   (`git@github.com:tett23/dotfiles.git`) に切り替える (ADR 0016)。
3. `bootstrap.sh` を実行する: Nix (Determinate Systems のインストーラ) を入れ、nix-darwin を適用する
   (初回は `nix run` で flake.lock に固定した nix-darwin を使う。ADR 0017)。
4. `mise install` で言語とツールを入れる。

- `DOTFILES` / `DOTFILES_REPO` / `DOTFILES_BRANCH` / `DOTFILES_REMOTE` で clone 先などを上書きできる。
- 画面にログインしていない状態 (SSH 越しなど) では LaunchAgent (colima) を登録できない。この場合は警告を出して
  `mise install` まで進め、ログイン後に `sudo darwin-rebuild switch --flake ~/dotfiles#dione` を実行するよう案内する。
  ログインしている状態で `bootstrap.sh` が失敗したときはそこで止まる (ADR 0024)。

## 依存の管理

- 依存の一覧は [dependencies.md](../dependencies.md) が一次ソース。
- CLI・GUI アプリ・macOS の設定は Nix (nix-darwin と、そのモジュールとしての home-manager) で管理する。
  Homebrew は使わない (ADR 0012)。
  - nixpkgs に無いアプリ (Claude デスクトップ、AquaSKK) は `nix/pkgs/` に自前のパッケージを置く。
  - Docker は colima で動かし、home-manager の LaunchAgent で常駐させる。
- 言語とツールは mise で管理する (`mise/config.toml`。すべて `latest`)。ghc は ghcup のプラグインで入れる (ADR 0018)。

### コマンド

| コマンド | 内容 |
|---|---|
| `bin/sync-deps` | `dependencies.md` を Claude (`claude -p`) に読ませ、`flake.nix`・`mise/config.toml`・`nix/pkgs/` を更新させる (ADR 0013) |
| `bin/update-nix` | `flake.lock` と `nix/pkgs/sources.json` を最新にして適用する (ADR 0012) |
| `bin/update-mise` | mise の言語とツールを最新にする。mise 本体は Nix で更新する (ADR 0012) |

## 設定ファイルの配置

home-manager が、リポジトリ内のファイルへのシンボリックリンク (`mkOutOfStoreSymlink`) を張る。
リポジトリを編集すると、`darwin-rebuild` をやり直さなくてもすぐに反映される。

| リンク先 | リンク元 |
|---|---|
| `~/.zshenv`、`~/.zshrc` | `zsh/zshenv`、`zsh/zshrc` |
| `~/.gitconfig`、`~/.gitignore_global` | `git/config`、`git/ignore` |
| `~/.tmux.conf` | `tmux/tmux.conf` |
| `~/.rubocop.yml` | `rubocop/config.yml` |
| `~/.claude/settings.json` | `claude/settings.json` |
| `~/.claude/CLAUDE.md` | `.claude/CLAUDE.md` |
| `~/.config/nvim`、`~/.config/karabiner` | `nvim/`、`karabiner/` |
| `~/.config/bat/config`、`~/.config/ghostty/config`、`~/.config/mise/config.toml` | `bat/config`、`ghostty/config`、`mise/config.toml` |
| `~/Library/Application Support/Code/User/` の `settings.json`・`keybindings.json`・`snippets` | `vscode/` |
| `~/Library/Application Support/AquaSKK/keymap.conf` | `skk/keymap.conf` |

## zsh

- プラグインは Zinit で遅延読み込みする。`eval "$(… init)"` の結果はキャッシュし、git の情報を表示するプロンプトは
  自前の軽量な実装 (`zsh/lib/git-prompt.zsh`) を使う (ADR 0011)。
- PATH の優先順位は、mise → `~/.local/bin`・`~/bin` → home-manager → Nix 本体 → システムの順 (ADR 0023)。
  `bin/` は末尾に足す。
- nix-daemon.sh は読み込まない (tmux の中で `NIX_PROFILES` が上書きされるのを防ぐ。ADR 0020)。
- 履歴は `$XDG_STATE_HOME/zsh/history` に 50 万件まで保存する。先頭が空白のコマンドは残さない (ADR 0023)。
- fzf のファイル検索は fd を使う (ADR 0002)。主なキー割り当て:

| キー | 内容 |
|---|---|
| `Ctrl-P` | ファイルを検索して入力行に挿入する |
| `Ctrl-G` | リポジトリを選んで移動する |
| `Ctrl-B` | git のブランチを選んで切り替える |
| `Ctrl-F` | `git status` の項目を選ぶ |
| `Ctrl-K` | プロセスを選んで終了させる |

## nvim

- カラースキームは monokai-pro.nvim の `classic` フィルタ (ADR 0009)。
- 不可視文字を表示する (ADR 0028)。タブ (`>-`)、行末の空白 (`_`)、ノーブレークスペース (`+`)、すべての半角スペース (`·`)、
  改行 (`↲`) は記号で、全角スペースは背景色で示す。色はコメントより明るい `#919288`。
- 選択範囲 (`Visual`) の背景色は、テーマの既定 (約 `#3e3f38`) では見分けにくいため `#55564e` に上書きしている (ADR 0026)。

## tmux

- プレフィックスは `Ctrl-Q`。プラグインマネージャー (TPM) は使わない (ADR 0029)。
  - ステータスラインは tmux-nova で組み立てる。Nix (`pkgs.tmuxPlugins.tmux-nova`) で入れ、
    `~/.config/tmux/plugins/tmux-nova` にリンクして `tmux.conf` から読み込む。バージョンは `flake.lock` で固定される。
  - tmux-sensible・tmux-yank は使わず、必要な設定と割り当てを `tmux.conf` に書いている。
- コピーモード (vi) の `y` とマウスでの選択はクリップボードへ、`Y` は入力欄へ貼り付ける。
  `prefix + y` はシェルの入力行を、`prefix + Y` はペインのカレントディレクトリのパスをクリップボードへコピーする
  (`prefix + y` は zsh の vi モードが前提)。
- スクロールバックは 200 万行。
- ステータスラインのウィンドウ名には、実行中のプロセス名ではなくディレクトリ名を出す (ADR 0007)。

## Claude Code

- 本人の設定は `claude/settings.json`、全リポジトリ共通の指示は `.claude/CLAUDE.md`。
- mod `usage-hint` (`claude/mods/usage-hint/`) が、入力欄の下に `5h 23% · 7d 41% · Fable 12% · ctx 37%` の形で
  使用量を表示する (ADR 0004)。
  - 値が無い項目は `--`。75% を超えた項目は黄色にし (ADR 0005)、ラベルは太字にする (ADR 0006)。
  - セッション開始直後は、前回保存したレートリミットの値と、ローカルで推定したコンテキストの使用率を出す (ADR 0008)。
- `bin/orch` は、Claude から `codex exec` / `claude -p` へ作業を委譲する道具。モデルは別名で指定する
  (`opus`、`sonnet`、`haiku`、`fable`、`sol`。既定値は環境変数 `ORCH_MODEL_<別名>` で上書きできる。ADR 0024)。

## その他のコマンド (`bin/`)

| コマンド | 内容 |
|---|---|
| `send-to-kindle [--env-file <パス>] <ファイル>` | ファイルを Kindle のメールアドレスへ送る。設定は `--env-file` で指定したファイル、指定が無ければカレントディレクトリの `.env`、それも無ければ環境変数から読む (ADR 0021, 0022)。1 ファイルで完結し、テストも同じファイルにある (ADR 0025) |
| `rtouch <パス>` | 親ディレクトリを作ってからファイルを作る |
| `docker-sh <イメージ> …`、`figrm <サービス> …` | `docker run --rm -it`、`docker compose run --rm` の短縮 |
| `short-pwd` | カレントディレクトリを短縮して表示する |

## CI

GitHub Actions (`.github/workflows/ci.yml`) で次を確かめる。

- シェルスクリプトの shellcheck
- zsh のテスト (`zsh/tests/`)
- send-to-kindle のテスト (`deno test -A --ext=ts bin/send-to-kindle`)
- nix-darwin の設定の評価 (`nix eval`)

## ADR の運用

- 実装の前に ADR を書く。ファイル名は `docs/adr/0001-feature-details.md` のように 4 桁の連番を付ける。
- コミットした ADR はステータスの行を除いて変更しない。仕様を変えるときは新しい ADR を作る。

### 破棄した ADR

なし。
