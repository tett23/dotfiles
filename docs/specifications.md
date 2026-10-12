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

`install.sh` は冪等で、次を順に行う ([ADR 0001](adr/0001-curl-sh-install.md))。失敗したら同じコマンドを再実行する。

1. Xcode Command Line Tools を入れる。
2. `~/dotfiles` に HTTPS で clone する。その後 `origin` を SSH の URL
   (`git@github.com:tett23/dotfiles.git`) に切り替える ([ADR 0016](adr/0016-ssh-origin-after-install.md))。
3. `bootstrap.sh` を実行する: Nix (Determinate Systems のインストーラ) を入れ、nix-darwin を適用する
   (初回は `nix run` で flake.lock に固定した nix-darwin を使う。[ADR 0017](adr/0017-fix-bootstrap-first-darwin-rebuild.md))。
4. `mise install` で言語とツールを入れる。
5. mise で入れた ghcup で、Haskell の ghc・cabal の `latest` を入れて既定にする ([ADR 0050](adr/0050-ghc-cabal-via-ghcup.md))。
6. git の hook (`.githooks`) を有効にする ([ADR 0032](adr/0032-adr-guard.md))。

- `DOTFILES` / `DOTFILES_REPO` / `DOTFILES_BRANCH` / `DOTFILES_REMOTE` で clone 先などを上書きできる。
  `DOTFILES_SKIP_HASKELL=1` で、5 (ghc は大きい) を省ける。
- 画面にログインしていない状態 (SSH 越しなど) では LaunchAgent (colima) を登録できない。この場合は警告を出して
  `mise install` まで進め、ログイン後に `sudo darwin-rebuild switch --flake ~/dotfiles#dione` を実行するよう案内する。
  ログインしている状態で `bootstrap.sh` が失敗したときはそこで止まる ([ADR 0024](adr/0024-orch-models-and-headless-install.md))。

## 依存の管理

- 依存の一覧は [dependencies.md](../dependencies.md) が一次ソース。
- CLI・GUI アプリ・macOS の設定は Nix (nix-darwin と、そのモジュールとしての home-manager) で管理する。
  Homebrew は使わない ([ADR 0012](adr/0012-remove-homebrew.md))。
  - nixpkgs に無いアプリ (Claude デスクトップ、AquaSKK) は `nix/pkgs/` に自前のパッケージを置く。
  - Docker は colima で動かし、home-manager の LaunchAgent で常駐させる。
- 言語とツールは mise で管理する (`mise/config.toml`。すべて `latest`)。Haskell の ghc・cabal は mise で入れた ghcup で入れ、
  `install.sh` と `bin/update-mise` が ghcup の `latest` を入れて既定にする ([ADR 0050](adr/0050-ghc-cabal-via-ghcup.md))。
  VSCode の Haskell 拡張も mise の ghcup を使い、ghcup の自動の更新はしない。stack は入れない ([ADR 0056](adr/0056-remove-old-ghcup-and-stack.md))。

### コマンド

| コマンド          | 内容                                                                                                                     |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `bin/sync-deps`   | `dependencies.md` を Claude (`claude -p`) に読ませ、`flake.nix`・`mise/config.toml`・`nix/pkgs/` を更新させる ([ADR 0013](adr/0013-generate-config-from-dependencies-with-claude.md)) |
| `bin/update-nix`  | `flake.lock` と `nix/pkgs/sources.json` を最新にして適用する ([ADR 0012](adr/0012-remove-homebrew.md))                                                  |
| `bin/update-mise` | mise の言語とツールを最新にする。mise 本体は Nix で更新する ([ADR 0012](adr/0012-remove-homebrew.md))                                                   |

## 設定ファイルの配置

home-manager が、リポジトリ内のファイルへのシンボリックリンク (`mkOutOfStoreSymlink`) を張る。
リポジトリを編集すると、`darwin-rebuild` をやり直さなくてもすぐに反映される。
設定は XDG の場所 (`~/.config/<ツール>/`) に置き、ホーム直下には `~/.zshenv` だけを置く ([ADR 0042](adr/0042-xdg-config-locations.md))。

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
  自前の軽量な実装 (`zsh/lib/git-prompt.zsh`) を使う ([ADR 0011](adr/0011-speed-up-zsh-startup.md))。
- `~/.zshenv` で `ZDOTDIR` を `~/.config/zsh` にし、`.zshrc` はそこから読む ([ADR 0042](adr/0042-xdg-config-locations.md))。インストーラなどの `~/.zshrc` への追記は
  読まれないので、必要なものは `zsh/zshrc.mine` (`~/.config/zsh/.zshrc.mine` のリンク元。git で管理するので秘密は書かない。
  [ADR 0043](adr/0043-remove-vimbackup-and-zshrc-mine.md)) に書く。補完のキャッシュは `~/.cache/zsh/zcompdump` に置く。
- PATH 以外の環境変数 (`LANG`・`EDITOR`・`XDG_*`・`MISE_TRUSTED_CONFIG_PATHS`) は `~/.zshenv` で設定し、`zsh -c` などの非対話のシェルにも届ける。
  PATH は `~/.zshenv` では変えず、`zsh/exports.sh` (`.zshrc` から読む) で設定する ([ADR 0055](adr/0055-improvements-2026-10-13.md)。理由は [ADR 0010](adr/0010-fix-zsh-fzf-audit.md))。
- PATH の優先順位は、mise → `~/.local/bin`・`~/bin` → home-manager → Nix 本体 → システムの順 ([ADR 0023](adr/0023-fix-remaining-audit-items-2.md))。
  `bin/` と、ghcup で入れたツールの `~/.ghcup/bin` は末尾に足す (`~/.ghcup/env` は PATH の先頭に入れるので読まない。[ADR 0050](adr/0050-ghc-cabal-via-ghcup.md))。
- nix-daemon.sh は読み込まない (tmux の中で `NIX_PROFILES` が上書きされるのを防ぐ。[ADR 0020](adr/0020-stop-sourcing-nix-daemon-sh.md))。
- 履歴は `$XDG_STATE_HOME/zsh/history` に 50 万件まで保存する。先頭が空白のコマンドは残さない ([ADR 0023](adr/0023-fix-remaining-audit-items-2.md))。
- 補完は、小文字の入力を大文字にも一致させる ([ADR 0034](adr/0034-small-conveniences-zsh-fzf-nvim.md))。`Tab` の補完候補は fzf-tab で絞り込み、`cd` の補完では
  候補のディレクトリの中身をプレビューする ([ADR 0037](adr/0037-fzf-tab-flash-treesitter-context-trouble.md)。fzf 本体の `**<Tab>` は使わない)。
  zsh の補完の一覧での選択は使わず (`menu no`)、候補はグループの見出し (`[%d]`) 付きで fzf-tab に渡す ([ADR 0055](adr/0055-improvements-2026-10-13.md))。
- 補完の候補には `.` で始まるファイル・ディレクトリも出す。`.git` と、git が無視するもの (`.gitignore` などで除外したもの) は
  候補から外す (ほかに候補が無いときは出る。[ADR 0038](adr/0038-search-hidden-files.md))。
- eza と bat の短いエイリアス ([ADR 0035](adr/0035-eza-and-bat-aliases.md), [0053](adr/0053-bat-manpager-and-eza-options.md), [0057](adr/0057-remaining-improvements-2.md)): `e` (`eza --icons=auto --group-directories-first --hyperlink`)、`el` (`e -l --git`)、
  `ea` (`e -a`)、`ela` (`e -la --git`)、`et` (`e --tree --git-ignore`)、`b` (`bat`)。アイコンは端末に出すときだけ付き、詳細表示には git の状態の列が出る。
  ファイル名は端末のリンクになり、Ghostty では `Cmd` を押しながらクリックすると開ける。ツリーには `.gitignore` で除外したものを出さない。
- bat-extras の `batgrep` (ripgrep の結果を bat で出す) と `batdiff` (git の差分を bat で出す) を入れる ([ADR 0057](adr/0057-remaining-improvements-2.md))。
- bat は、拡張子・ファイル名で言語が決まらない設定ファイルにも色を付ける (`bat/config` の `--map-syntax`。[ADR 0059](adr/0059-bat-map-syntax-and-nvim-options.md))。
  dotfiles の中の `git/config`・`git/ignore` は git の設定、`.zshrc.mine` は bash。bat に言語が無い Ghostty の設定は INI、`tmux.conf` は bash で代える。
- `man` のページは bat で色付きで表示する (`MANPAGER`。[ADR 0053](adr/0053-bat-manpager-and-eza-options.md))。
- fzf のファイル検索は fd を使い ([ADR 0002](adr/0002-fzf-file-search-with-fd.md))、`Ctrl-P` では bat でファイルの先頭をプレビューする ([ADR 0034](adr/0034-small-conveniences-zsh-fzf-nvim.md), [0036](adr/0036-tmux-window-switcher-on-ctrl-t.md))。主なキー割り当て:

| キー     | 内容                               |
| -------- | ---------------------------------- |
| `Ctrl-P` | ファイルを検索して入力行に挿入する |
| `Ctrl-G` | リポジトリを選んで移動する         |
| `Ctrl-B` | git のブランチを選んで切り替える   |
| `Ctrl-F` | `git status` の項目を選ぶ          |
| `Ctrl-K` | プロセスを選んで終了させる         |
| `Ctrl-R` | 履歴を検索する (fzf 本体)。選んでいるコマンドの全体を下に bat で色付きで出し、`Ctrl-O` で表示を切り替える ([ADR 0057](adr/0057-remaining-improvements-2.md)) |
| `Ctrl-O` | `zsh/fzf.sh` の fzf のコマンド (`__` 付きの関数) を、キーと説明つきの一覧から選んで実行する ([ADR 0031](adr/0031-command-finder-key-and-rust-tools-via-mise.md), [0033](adr/0033-fzf-tmux-window-switcher.md)) |
| `Ctrl-T` | tmux の全セッションのウィンドウを選んで切り替える (tmux の割り当て。下の tmux の節。[ADR 0033](adr/0033-fzf-tmux-window-switcher.md), [0036](adr/0036-tmux-window-switcher-on-ctrl-t.md), [0052](adr/0052-tmux-window-switcher-in-tmux.md))。fzf 本体の `Ctrl-T` (ファイルの選択) は `Ctrl-P` で使う |
| `v` (ノーマルモード)・`Ctrl-X Ctrl-E` | 入力中のコマンドを nvim で編集する ([ADR 0034](adr/0034-small-conveniences-zsh-fzf-nvim.md)) |

## nvim

- カラースキームは monokai-pro.nvim の `classic` フィルタ ([ADR 0009](adr/0009-fix-git-tmux-nvim-audit.md))。
- 不可視文字を表示する ([ADR 0028](adr/0028-nvim-show-invisible-characters.md))。タブ (`>-`)、行末の空白 (`_`)、ノーブレークスペース (`+`)、すべての半角スペース (`·`)、
  改行 (`↲`) は記号で、全角スペースは背景色で示す。色は緑 `#76b98e` (灰色の本文・コメントと色味で区別でき、文字列の黄緑より暗い。[ADR 0028](adr/0028-nvim-show-invisible-characters.md) の色の値の調整)。
- 選択範囲 (`Visual`) の背景色は、テーマの既定 (約 `#3e3f38`) では見分けにくいため `#55564e` に上書きしている ([ADR 0026](adr/0026-nvim-visual-selection-color.md))。
- カーソルの上下に常に 8 行を残す (`scrolloff`)。記号の列は常に出し、記号の出入りで本文がずれないようにする (`signcolumn = "yes"`)。
  `:s` の置き換えの結果は、画面外の行も含めて下の分割に出す (`inccommand = "split"`。[ADR 0059](adr/0059-bat-map-syntax-and-nvim-options.md))。
- nvim を閉じた後も undo できる (`undofile`)。ヤンクした範囲を一瞬光らせ、ファイルは前回のカーソル位置から開く
  (git のコミットメッセージなどを除く。[ADR 0034](adr/0034-small-conveniences-zsh-fzf-nvim.md))。
- 移動・表示の補助 ([ADR 0037](adr/0037-fzf-tab-flash-treesitter-context-trouble.md)):
  - flash.nvim: `s` で入力した文字の位置へ移動、`S` で構文の単位で範囲を選ぶ (既定の `s`・`S` の置き換えは `cl`・`cc` を使う)。
    オペレータ待ちの `r` は離れた場所への操作、`R` は構文の単位での検索。`/` の検索中の `Ctrl-S` でラベルの表示を切り替える。
  - nvim-treesitter-context: 今いる関数・クラスの先頭行を画面上部に固定表示する (最大 3 行)。
  - trouble.nvim: `<Leader>xx` で全体の診断、`<Leader>xX` で今のバッファの診断、`<Leader>xq` で quickfix リストを開閉する。
- which-key のキーの一覧のアイコンには mini.icons を使う ([ADR 0039](adr/0039-fix-nvim-checkhealth.md))。
- `<Leader>t` で新しいタブを開く (`T` は flash.nvim の後方への文字の移動。[ADR 0045](adr/0045-fix-audit-failures-and-risks.md))。
- LSP は mason で入れたサーバーを有効にする。rubocop・stylua は LSP にせず、診断は nvim-lint、整形は conform で行う
  (Lua の整形は stylua。[ADR 0045](adr/0045-fix-audit-failures-and-risks.md))。`<Leader>fmt` も保存時と同じく conform で整形する
  (conform に整形の道具が無ければ LSP で整形する。[ADR 0055](adr/0055-improvements-2026-10-13.md))。
- 診断のメッセージは行の右に出し、重いものを優先して並べる (`virtual_text`・`severity_sort`。[ADR 0055](adr/0055-improvements-2026-10-13.md))。
- Telescope のファイル検索 (`<Leader><Leader>`・`<Leader>ff`) と文字列の検索 (`<Leader>fg`) は、`.` で始まるファイルも対象にする。
  `.gitignore` に従い、`.git` の中は除く (zsh の `Ctrl-P` と同じ。[ADR 0038](adr/0038-search-hidden-files.md))。

## Ghostty

- 終了時の確認を出さず、最後のウィンドウを閉じたら終了する。
- `Cmd+P` は Kitty のキーの形式 (`CSI 112;9u`) で送り、nvim の `<D-p>` (コマンドパレット) で受ける。`Ctrl+J` は送らない。
- Option キーは Alt として送らない (Ghostty の既定。[ADR 0047](adr/0047-ghostty-option-as-alt-removed.md))。左の Option は Karabiner-Elements で Escape に置き換えているので、
  左の Option (= Escape) に続けて素早くキーを押すと `Alt-c` などと同じ入力になる (zsh は vi モードなので、`KEYTIMEOUT` の 0.4 秒より
  遅いとノーマルモードに入る)。右の Option では特殊な文字を入力する。
- 自動更新はしない (Nix で入れていて、`bin/update-nix` で上げる。[ADR 0044](adr/0044-ghostty-conveniences.md))。
- 配色は nvim と揃えて `Monokai Classic`。`Cmd+\` で、どのアプリからでも画面の上から端末 (quick terminal) を出し入れする。
  終了したときのウィンドウ・タブの配置を、次の起動で戻す。ウィンドウの余白は上下左右で均等にする ([ADR 0044](adr/0044-ghostty-conveniences.md))。
- フォントは指定しない (英数字は Ghostty に組み込みの JetBrains Mono)。日本語の文字 (和文の記号・ひらがな・カタカナ・漢字・
  全角の英数字) は、等幅のゴシック体の BIZ UDゴシックで表示する (`font-codepoint-map`。[ADR 0048](adr/0048-ghostty-japanese-font.md))。
- 合字 (リガチャ) は使わず、`<-`・`->`・`!=` などを 1 文字ずつ表示する (`font-feature` で `calt`・`liga`・`dlig` を無効。[ADR 0049](adr/0049-ghostty-disable-ligatures.md))。

## tmux

- プレフィックスは `Ctrl-Q` (既定の `Ctrl-B` の割り当ては外す。[ADR 0055](adr/0055-improvements-2026-10-13.md))。プラグインマネージャー (TPM) は使わない ([ADR 0029](adr/0029-tmux-without-tpm.md))。
  - ステータスラインは tmux-nova で組み立てる。Nix (`pkgs.tmuxPlugins.tmux-nova`) で入れ、
    `~/.config/tmux/plugins/tmux-nova` にリンクして `tmux.conf` から読み込む。バージョンは `flake.lock` で固定される。
  - tmux-sensible・tmux-yank は使わず、必要な設定と割り当てを `tmux.conf` に書いている。
- コピーモード (vi) の `y` とマウスでの選択はクリップボードへ、`Y` は入力欄へ貼り付ける。
  `prefix + y` はシェルの入力行を、`prefix + Y` はペインのカレントディレクトリのパスをクリップボードへコピーする
  (`prefix + y` は zsh の vi モードが前提)。
- スクロールバックは 200 万行。
- 表示中のペインのプログラムが送る端末への制御 (画像の表示など) は、tmux を通さずに Ghostty に通す (`allow-passthrough on`。[ADR 0054](adr/0054-tmux-allow-passthrough.md))。
- ペインのプログラムが出す端末のリンク (OSC 8) を Ghostty に渡す (`terminal-features` の `hyperlinks`。[ADR 0057](adr/0057-remaining-improvements-2.md))。
- `Shift+Enter` などの修飾キーの組み合わせを、ペインのプログラムに渡す (`extended-keys on`。[ADR 0055](adr/0055-improvements-2026-10-13.md))。
- `Ctrl-T` (prefix 無し) で、ポップアップの中で全セッションのウィンドウを fzf で選んで切り替える (`tmux/scripts/window-switcher`)。
  一覧には今いるウィンドウに `*` を付け、プレビューにそのウィンドウの画面を出す。tmux が先に受け取るので、zsh・nvim のどちらでも効く
  (nvim の `Ctrl-T` は使えない。[ADR 0052](adr/0052-tmux-window-switcher-in-tmux.md))。
- ステータスラインのウィンドウ名には、実行中のプロセス名ではなくディレクトリ名を出す ([ADR 0007](adr/0007-tmux-status-directory-name.md))。

## git

- 主な設定 (`git/config`): コミットのメッセージを書く画面に差分を出す (`commit.verbose`)。`git branch` は最近更新した順に並べ (`branch.sort`)、
  一覧は端末の幅に合わせて複数列で出す (`column.ui`)。`rebase -i` で `fixup!`・`squash!` のコミットを自動で並べる (`rebase.autoSquash`)。
  `git push` で注釈付きのタグも送る (`push.followTags`。[ADR 0055](adr/0055-improvements-2026-10-13.md))。
- fetch・clone・push で受け取るオブジェクトを検査する (`transfer.fsckObjects`。[ADR 0058](adr/0058-git-fsck-and-vscode-cleanup.md))。
- `git mergetool` はファイルごとの確認を出さない (`difftool` と同じ)。同じ働きのエイリアスは 1 つにまとめた (`lg`・`cia` を残す。[ADR 0057](adr/0057-remaining-improvements-2.md))。

## Claude Code

- 本人の設定は `.claude/settings.json`、全リポジトリ共通の指示は `.claude/CLAUDE.md`。
- ステータスラインには、モデル名・ディレクトリ名・費用を出す (jq を 1 回だけ起動する)。コンテキストの使用率は usage-hint が出すので出さない ([ADR 0057](adr/0057-remaining-improvements-2.md))。
- mod `usage-hint` (`.claude/mods/usage-hint/`) が、入力欄の下に `5h 23% · 7d 41% · Fable 12% · ctx 37%` の形で
  使用量を表示する ([ADR 0004](adr/0004-usage-hint-mod.md))。
  - 値が無い項目は `--`。75% を超えた項目は暗めの黄色 (`#b39020`)、90% を超えた項目は暗めの赤 (`#b5403a`) にし
    ([ADR 0005](adr/0005-usage-hint-warning-color.md), [0060](adr/0060-usage-hint-danger-color.md))、ラベルは太字にする ([ADR 0006](adr/0006-usage-hint-bold-labels.md))。
  - セッション開始直後は、前回保存したレートリミットの値と、ローカルで推定したコンテキストの使用率を出す ([ADR 0008](adr/0008-usage-hint-initial-values.md))。
- `bin/orch` は、Claude から `codex exec` / `claude -p` へ作業を委譲する道具。モデルは別名で指定する
  (`opus`、`sonnet`、`haiku`、`fable`、`sol`。既定値は環境変数 `ORCH_MODEL_<別名>` で上書きできる。[ADR 0024](adr/0024-orch-models-and-headless-install.md))。

## その他のコマンド (`bin/`)

| コマンド                                        | 内容                                                                                                                                                                                                                                      |
| ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `rtouch <パス>`                                 | 親ディレクトリを作ってからファイルを作る                                                                                                                                                                                                  |
| `docker-sh <イメージ> …`、`figrm <サービス> …`  | `docker run --rm -it`、`docker compose run --rm` の短縮                                                                                                                                                                                   |
| `short-pwd`                                     | カレントディレクトリを短縮して表示する                                                                                                                                                                                                    |

## 自作のツール (mise で入れる)

別のリポジトリで管理している自作のツールを、mise で入れる ([ADR 0031](adr/0031-command-finder-key-and-rust-tools-via-mise.md))。仕様はそれぞれのリポジトリを参照。

| コマンド | 内容 | 入れ方 |
|---|---|---|
| `send-to-kindle` | ファイルを Kindle のメールアドレスへ送る (https://github.com/tett23/send-to-kindle) | GitHub のリリースのバイナリ |
| `shorten-path` | パスを短縮して表示する。`bin/short-pwd` が使う (https://github.com/tett23/shorten-path) | GitHub のリリースのバイナリ |

## CI

GitHub Actions (`.github/workflows/ci.yml`) で次を確かめる。

- シェルスクリプトの shellcheck
- zsh のテスト (`zsh/tests/*.test.zsh` をすべて。[ADR 0046](adr/0046-fix-audit-non-breaking.md))
- コミット済みの ADR が変更されていないこと (adr-guard。[ADR 0032](adr/0032-adr-guard.md))
- nix-darwin の設定の評価 (`nix eval`。Nix は `DeterminateSystems/determinate-nix-action@v3` で入れる。[ADR 0046](adr/0046-fix-audit-non-breaking.md))

同じブランチ・PR の古い実行は取り消し、各ジョブには時間の上限を付けている ([ADR 0046](adr/0046-fix-audit-non-breaking.md))。自前のパッケージのビルドと、
usage-hint の mod のテストは CI では行わない (本人の判断。[ADR 0046](adr/0046-fix-audit-non-breaking.md))。

## ADR の運用

- 実装の前に ADR を書く。ファイル名は `docs/adr/0001-feature-details.md` のように 4 桁の連番を付ける。
- コミットした ADR はステータスの行を除いて変更しない。仕様を変えるときは新しい ADR を作る。
- この規則は adr-guard (https://github.com/tett23/adr-guard) で、git の pre-commit hook (`.githooks/pre-commit`)・
  Claude Code の hook (`.claude/settings.json`。全リポジトリで有効)・CI の `adr` ジョブの 3 か所で強制する ([ADR 0032](adr/0032-adr-guard.md))。
  - adr-guard が変更を許すのは `ステータス:` で始まる行だけ。[ADR 0001](adr/0001-curl-sh-install.md)〜[0025](adr/0025-send-to-kindle-single-file.md) は `- Status:` の書き方のため、
    ステータスを更新しない。置き換えた関係は新しい ADR の「文脈」に書く。
  - `core.hooksPath` は clone ごとの設定で、`install.sh` が設定する。

### 破棄・却下した ADR

- [ADR 0040](adr/0040-trailing-blank-line.md) (却下): nvim で保存するときにファイルの末尾に空行を 1 行残す。整形ツール (prettier・gofmt・rubocop など) が
  末尾の空行を消すため、ほかのリポジトリの CI の検査 (`prettier --check` など) に引っかかり、保存のたびに undo の履歴も
  増えるため、採らなかった。nvim は既定 (`fixendofline`) どおり、最後の行の後に改行を 1 つ付けて保存する。
