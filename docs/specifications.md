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
2. `~/dotfiles` に HTTPS で clone する。その後 `origin` を SSH の URL
   (`git@github.com:tett23/dotfiles.git`) に切り替える (ADR 0016)。
3. `bootstrap.sh` を実行する: Nix (Determinate Systems のインストーラ) を入れ、nix-darwin を適用する
   (初回は `nix run` で flake.lock に固定した nix-darwin を使う。ADR 0017)。
4. `mise install` で言語とツールを入れる。
5. mise で入れた ghcup で、Haskell の ghc・cabal の `latest` を入れて既定にする (ADR 0050)。
6. git の hook (`.githooks`) を有効にする (ADR 0032)。

- `DOTFILES` / `DOTFILES_REPO` / `DOTFILES_BRANCH` / `DOTFILES_REMOTE` で clone 先などを上書きできる。
  `DOTFILES_SKIP_HASKELL=1` で、5 (ghc は大きい) を省ける。
- 画面にログインしていない状態 (SSH 越しなど) では LaunchAgent (colima) を登録できない。この場合は警告を出して
  `mise install` まで進め、ログイン後に `sudo darwin-rebuild switch --flake ~/dotfiles#dione` を実行するよう案内する。
  ログインしている状態で `bootstrap.sh` が失敗したときはそこで止まる (ADR 0024)。

## 依存の管理

- 依存の一覧は [dependencies.md](../dependencies.md) が一次ソース。
- CLI・GUI アプリ・macOS の設定は Nix (nix-darwin と、そのモジュールとしての home-manager) で管理する。
  Homebrew は使わない (ADR 0012)。
  - nixpkgs に無いアプリ (Claude デスクトップ、AquaSKK) は `nix/pkgs/` に自前のパッケージを置く。
  - Docker は colima で動かし、home-manager の LaunchAgent で常駐させる。
- 言語とツールは mise で管理する (`mise/config.toml`。すべて `latest`)。Haskell の ghc・cabal は mise で入れた ghcup で入れ、
  `install.sh` と `bin/update-mise` が ghcup の `latest` を入れて既定にする (ADR 0050)。

### コマンド

| コマンド          | 内容                                                                                                                     |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `bin/sync-deps`   | `dependencies.md` を Claude (`claude -p`) に読ませ、`flake.nix`・`mise/config.toml`・`nix/pkgs/` を更新させる (ADR 0013) |
| `bin/update-nix`  | `flake.lock` と `nix/pkgs/sources.json` を最新にして適用する (ADR 0012)                                                  |
| `bin/update-mise` | mise の言語とツールを最新にする。mise 本体は Nix で更新する (ADR 0012)                                                   |

## 設定ファイルの配置

home-manager が、リポジトリ内のファイルへのシンボリックリンク (`mkOutOfStoreSymlink`) を張る。
リポジトリを編集すると、`darwin-rebuild` をやり直さなくてもすぐに反映される。
設定は XDG の場所 (`~/.config/<ツール>/`) に置き、ホーム直下には `~/.zshenv` だけを置く (ADR 0042)。

| リンク先                                                                                      | リンク元                                           |
| --------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| `~/.zshenv`、`~/.config/zsh/.zshrc`、`~/.config/zsh/.zshrc.mine` | `zsh/zshenv`、`zsh/zshrc`、`zsh/zshrc.mine` |
| `~/.config/git/config`、`~/.config/git/ignore` | `git/config`、`git/ignore` |
| `~/.config/tmux/tmux.conf` | `tmux/tmux.conf` |
| `~/.config/rubocop/config.yml` | `rubocop/config.yml` |
| `~/.claude/settings.json`                                                                     | `.claude/settings.json`                            |
| `~/.claude/CLAUDE.md`                                                                         | `.claude/CLAUDE.md`                                |
| `~/.config/nvim`、`~/.config/karabiner`                                                       | `nvim/`、`karabiner/`                              |
| `~/.config/bat/config`、`~/.config/ghostty/config`、`~/.config/mise/config.toml`              | `bat/config`、`ghostty/config`、`mise/config.toml` |
| `~/Library/Application Support/Code/User/` の `settings.json`・`keybindings.json`・`snippets` | `vscode/`                                          |
| `~/Library/Application Support/AquaSKK/keymap.conf`                                           | `skk/keymap.conf`                                  |

## zsh

- プラグインは Zinit で遅延読み込みする。`eval "$(… init)"` の結果はキャッシュし、git の情報を表示するプロンプトは
  自前の軽量な実装 (`zsh/lib/git-prompt.zsh`) を使う (ADR 0011)。
- `~/.zshenv` で `ZDOTDIR` を `~/.config/zsh` にし、`.zshrc` はそこから読む (ADR 0042)。インストーラなどの `~/.zshrc` への追記は
  読まれないので、必要なものは `zsh/zshrc.mine` (`~/.config/zsh/.zshrc.mine` のリンク元。git で管理するので秘密は書かない。
  ADR 0043) に書く。補完のキャッシュは `~/.cache/zsh/zcompdump` に置く。
- PATH の優先順位は、mise → `~/.local/bin`・`~/bin` → home-manager → Nix 本体 → システムの順 (ADR 0023)。
  `bin/` と、ghcup で入れたツールの `~/.ghcup/bin` は末尾に足す (`~/.ghcup/env` は PATH の先頭に入れるので読まない。ADR 0050)。
- nix-daemon.sh は読み込まない (tmux の中で `NIX_PROFILES` が上書きされるのを防ぐ。ADR 0020)。
- 履歴は `$XDG_STATE_HOME/zsh/history` に 50 万件まで保存する。先頭が空白のコマンドは残さない (ADR 0023)。
- 補完は、小文字の入力を大文字にも一致させる (ADR 0034)。`Tab` の補完候補は fzf-tab で絞り込み、`cd` の補完では
  候補のディレクトリの中身をプレビューする (ADR 0037。fzf 本体の `**<Tab>` は使わない)。
- 補完の候補には `.` で始まるファイル・ディレクトリも出す。`.git` と、git が無視するもの (`.gitignore` などで除外したもの) は
  候補から外す (ほかに候補が無いときは出る。ADR 0038)。
- eza と bat の短いエイリアス (ADR 0035): `e` (`eza`)、`el` (`eza -l`)、`ea` (`eza -a`)、`ela` (`eza -la`)、
  `et` (`eza --tree`)、`b` (`bat`)。
- fzf のファイル検索は fd を使い (ADR 0002)、`Ctrl-P` では bat でファイルの先頭をプレビューする (ADR 0034, 0036)。主なキー割り当て:

| キー     | 内容                               |
| -------- | ---------------------------------- |
| `Ctrl-P` | ファイルを検索して入力行に挿入する |
| `Ctrl-G` | リポジトリを選んで移動する         |
| `Ctrl-B` | git のブランチを選んで切り替える   |
| `Ctrl-F` | `git status` の項目を選ぶ          |
| `Ctrl-K` | プロセスを選んで終了させる         |
| `Ctrl-O` | `zsh/fzf.sh` の fzf のコマンド (`__` 付きの関数) を、キーと説明つきの一覧から選んで実行する (ADR 0031, 0033) |
| `Ctrl-T` | tmux の全セッションのウィンドウを選んで切り替える。プレビューにウィンドウの画面を出す (ADR 0033, 0036)。fzf 本体の `Ctrl-T` (ファイルの選択) は `Ctrl-P` で使う |
| `v` (ノーマルモード)・`Ctrl-X Ctrl-E` | 入力中のコマンドを nvim で編集する (ADR 0034) |

## nvim

- カラースキームは monokai-pro.nvim の `classic` フィルタ (ADR 0009)。
- 不可視文字を表示する (ADR 0028)。タブ (`>-`)、行末の空白 (`_`)、ノーブレークスペース (`+`)、すべての半角スペース (`·`)、
  改行 (`↲`) は記号で、全角スペースは背景色で示す。色は緑 `#76b98e` (灰色の本文・コメントと色味で区別でき、文字列の黄緑より暗い。ADR 0028 の色の値の調整)。
- 選択範囲 (`Visual`) の背景色は、テーマの既定 (約 `#3e3f38`) では見分けにくいため `#55564e` に上書きしている (ADR 0026)。
- nvim を閉じた後も undo できる (`undofile`)。ヤンクした範囲を一瞬光らせ、ファイルは前回のカーソル位置から開く
  (git のコミットメッセージなどを除く。ADR 0034)。
- 移動・表示の補助 (ADR 0037):
  - flash.nvim: `s` で入力した文字の位置へ移動、`S` で構文の単位で範囲を選ぶ (既定の `s`・`S` の置き換えは `cl`・`cc` を使う)。
    オペレータ待ちの `r` は離れた場所への操作、`R` は構文の単位での検索。`/` の検索中の `Ctrl-S` でラベルの表示を切り替える。
  - nvim-treesitter-context: 今いる関数・クラスの先頭行を画面上部に固定表示する (最大 3 行)。
  - trouble.nvim: `<Leader>xx` で全体の診断、`<Leader>xX` で今のバッファの診断、`<Leader>xq` で quickfix リストを開閉する。
- which-key のキーの一覧のアイコンには mini.icons を使う (ADR 0039)。
- `<Leader>t` で新しいタブを開く (`T` は flash.nvim の後方への文字の移動。ADR 0045)。
- LSP は mason で入れたサーバーを有効にする。rubocop・stylua は LSP にせず、診断は nvim-lint、整形は conform で行う
  (Lua の整形は stylua。ADR 0045)。
- Telescope のファイル検索 (`<Leader><Leader>`・`<Leader>ff`) と文字列の検索 (`<Leader>fg`) は、`.` で始まるファイルも対象にする。
  `.gitignore` に従い、`.git` の中は除く (zsh の `Ctrl-P` と同じ。ADR 0038)。

## Ghostty

- 終了時の確認を出さず、最後のウィンドウを閉じたら終了する。
- `Cmd+P` は Kitty のキーの形式 (`CSI 112;9u`) で送り、nvim の `<D-p>` (コマンドパレット) で受ける。`Ctrl+J` は送らない。
- Option キーは Alt として送らない (Ghostty の既定。ADR 0047)。左の Option は Karabiner-Elements で Escape に置き換えているので、
  左の Option (= Escape) に続けて素早くキーを押すと `Alt-c` などと同じ入力になる (zsh は vi モードなので、`KEYTIMEOUT` の 0.4 秒より
  遅いとノーマルモードに入る)。右の Option では特殊な文字を入力する。
- 自動更新はしない (Nix で入れていて、`bin/update-nix` で上げる。ADR 0044)。
- 配色は nvim と揃えて `Monokai Classic`。`Cmd+\` で、どのアプリからでも画面の上から端末 (quick terminal) を出し入れする。
  終了したときのウィンドウ・タブの配置を、次の起動で戻す。ウィンドウの余白は上下左右で均等にする (ADR 0044)。
- フォントは指定しない (英数字は Ghostty に組み込みの JetBrains Mono)。日本語の文字 (和文の記号・ひらがな・カタカナ・漢字・
  全角の英数字) は、等幅のゴシック体の BIZ UDゴシックで表示する (`font-codepoint-map`。ADR 0048)。
- 合字 (リガチャ) は使わず、`<-`・`->`・`!=` などを 1 文字ずつ表示する (`font-feature` で `calt`・`liga`・`dlig` を無効。ADR 0049)。

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

- 本人の設定は `.claude/settings.json`、全リポジトリ共通の指示は `.claude/CLAUDE.md`。
- mod `usage-hint` (`.claude/mods/usage-hint/`) が、入力欄の下に `5h 23% · 7d 41% · Fable 12% · ctx 37%` の形で
  使用量を表示する (ADR 0004)。
  - 値が無い項目は `--`。75% を超えた項目は黄色にし (ADR 0005)、ラベルは太字にする (ADR 0006)。
  - セッション開始直後は、前回保存したレートリミットの値と、ローカルで推定したコンテキストの使用率を出す (ADR 0008)。
- `bin/orch` は、Claude から `codex exec` / `claude -p` へ作業を委譲する道具。モデルは別名で指定する
  (`opus`、`sonnet`、`haiku`、`fable`、`sol`。既定値は環境変数 `ORCH_MODEL_<別名>` で上書きできる。ADR 0024)。

## その他のコマンド (`bin/`)

| コマンド                                        | 内容                                                                                                                                                                                                                                      |
| ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `rtouch <パス>`                                 | 親ディレクトリを作ってからファイルを作る                                                                                                                                                                                                  |
| `docker-sh <イメージ> …`、`figrm <サービス> …`  | `docker run --rm -it`、`docker compose run --rm` の短縮                                                                                                                                                                                   |
| `short-pwd`                                     | カレントディレクトリを短縮して表示する                                                                                                                                                                                                    |

## 自作のツール (mise で入れる)

別のリポジトリで管理している自作のツールを、mise で入れる (ADR 0031)。仕様はそれぞれのリポジトリを参照。

| コマンド | 内容 | 入れ方 |
|---|---|---|
| `send-to-kindle` | ファイルを Kindle のメールアドレスへ送る (https://github.com/tett23/send-to-kindle) | GitHub のリリースのバイナリ |
| `shorten-path` | パスを短縮して表示する。`bin/short-pwd` が使う (https://github.com/tett23/shorten-path) | GitHub のリリースのバイナリ |

## CI

GitHub Actions (`.github/workflows/ci.yml`) で次を確かめる。

- シェルスクリプトの shellcheck
- zsh のテスト (`zsh/tests/*.test.zsh` をすべて。ADR 0046)
- コミット済みの ADR が変更されていないこと (adr-guard。ADR 0032)
- nix-darwin の設定の評価 (`nix eval`。Nix は `DeterminateSystems/determinate-nix-action@v3` で入れる。ADR 0046)

同じブランチ・PR の古い実行は取り消し、各ジョブには時間の上限を付けている (ADR 0046)。自前のパッケージのビルドと、
usage-hint の mod のテストは CI では行わない (本人の判断。ADR 0046)。

## ADR の運用

- 実装の前に ADR を書く。ファイル名は `docs/adr/0001-feature-details.md` のように 4 桁の連番を付ける。
- コミットした ADR はステータスの行を除いて変更しない。仕様を変えるときは新しい ADR を作る。
- この規則は adr-guard (https://github.com/tett23/adr-guard) で、git の pre-commit hook (`.githooks/pre-commit`)・
  Claude Code の hook (`.claude/settings.json`。全リポジトリで有効)・CI の `adr` ジョブの 3 か所で強制する (ADR 0032)。
  - adr-guard が変更を許すのは `ステータス:` で始まる行だけ。ADR 0001〜0025 は `- Status:` の書き方のため、
    ステータスを更新しない。置き換えた関係は新しい ADR の「文脈」に書く。
  - `core.hooksPath` は clone ごとの設定で、`install.sh` が設定する。

### 破棄・却下した ADR

- ADR 0040 (却下): nvim で保存するときにファイルの末尾に空行を 1 行残す。整形ツール (prettier・gofmt・rubocop など) が
  末尾の空行を消すため、ほかのリポジトリの CI の検査 (`prettier --check` など) に引っかかり、保存のたびに undo の履歴も
  増えるため、採らなかった。nvim は既定 (`fixendofline`) どおり、最後の行の後に改行を 1 つ付けて保存する。
