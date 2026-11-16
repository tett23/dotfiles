# dotfiles ベストプラクティス監査 (2026-10-11)

[2026-10-07 の監査](2026-10-07-best-practices.md)・[2026-10-09 の更新](2026-10-09-best-practices.md) の後の作業 ([ADR 0024](../adr/0024-orch-models-and-headless-install.md)〜0043) を
反映し、zsh・fzf・nvim・Nix とインストール・CI・git・tmux・そのほかを調べ直したもの。
分野ごとに調べ、指摘のうち重要なもの (故障・主なリスク) は実際にコマンドを実行して当てはまることを確かめた。

- 前回までに見送り・保留にしたもの (Z2・Z3・N6・L8・L19・G2・Z4) は対象外。
- ファイルの配置は [ファイル配置の監査](2026-10-11-file-layout-2.md) で扱う。

凡例: [故障] 動いていない / [リスク] 壊れうる・安全でない / [陳腐化] 古い書き方・設定 / [整理] 冗長・不揃い。
「挙動」は直すと使い勝手が変わるかどうか。

## まとめ

| 分野 | 故障 | リスク | 陳腐化 | 整理 |
|---|---|---|---|---|
| zsh・fzf (Z) | 3 | 5 | 2 | 3 |
| nvim (V) | 2 | 3 | 2 | 5 |
| Nix・インストール・CI (N) | 0 | 4 | 0 | 6 |
| git (G) | 1 | 1 | 0 | 3 |
| tmux (T) | 1 | 3 | 3 | 2 |
| Claude Code (C) | 0 | 1 | 1 | 2 |
| そのほか (O) | 1 | 0 | 2 | 2 |

前回からの持ち越し: 2026-10-09 の監査の **C2** (ステータスラインと usage-hint でコンテキストの使用率が重複) は未解決 (下の C2)。

## 故障

| ID | 場所 | 内容 | 直し方 | 挙動 |
|---|---|---|---|---|
| Z1 | `zsh/docker.sh:2` | `figbe` が `figrm bundle exec "$@"` で、サービス名の前に `bundle` を渡している。`figbe web rails c` が `docker compose run --rm bundle exec web …` になる | `figrm "$1" bundle exec "${@:2}"` | あり |
| Z2 | `zsh/fzf.sh` (`__yarn_workspaces`) | Yarn v1 専用の `yarn workspaces info` を使っているが、入っているのは Yarn 4.18.1 | `yarn workspaces list --json \| jq -r .name` | あり |
| Z3 | `zsh/langs/go.sh:2` | `command -v go` が `mise activate` より前に評価されるため、新しいログインシェル (`env -i` で確認) では `GOPATH` が空で、`~/repositories/bin` も PATH に入らない (tmux の中では親の環境を引き継ぐので動いて見える) | 条件を外して `GOPATH` を設定する | あり |
| V1 | `nvim/lua/config/keymaps.lua:14` | `<S-t>` (= `T`) に `:tabedit` を割り当てているが、[ADR 0037](../adr/0037-fzf-tab-flash-treesitter-context-trouble.md) の flash.nvim が `f`・`F`・`t`・`T` を上書きするため、ノーマルモードで `T` を押してもタブが開かない (確認済み)。もともと標準の `T` (後方への文字移動) も潰していた | タブを開くキーを別のキー (`<Leader>t` など) に移す | あり |
| V2 | `nvim/lua/plugins/completion.lua:5` | nvim-cmp が `InsertEnter` でだけ読み込まれるため、`:` のコマンドライン補完は一度挿入モードに入るまで効かない | `event = { "InsertEnter", "CmdlineEnter" }` | あり |
| G1 | `git/config:42` | エイリアス `today` は `!` が無いのでシェルを通らず、`$(git config user.name)` がそのまま文字列になる。今日のコミットがあっても 0 件になる (確認済み) | `!git log --since=midnight --author="$(git config user.name)" --oneline` | あり |
| T1 | `tmux/statuses.conf:30` | `@nova-pane` の `${pane_mode}` が、設定を読む時点で (空の) 環境変数として展開され、コピーモード中のモード名が出ない (確認済み) | `#{pane_mode}` にする | あり |
| O1 | `tmux/scripts/lan-ip` | 流用した古いスクリプトで、macOS では使われない Linux の分岐、誤った配列の扱い、`${lan_ip-N/a}` (空文字のとき `N/a` にならない) が残る | `ipconfig getifaddr` と既定の経路のインターフェースを使う数行に置き換える | 小 |

## リスク

| ID | 場所 | 内容 | 直し方 | 挙動 |
|---|---|---|---|---|
| Z4 | `zsh/common.sh:70` | `setopt complete_aliases` で、補完の前にエイリアスが展開されないため、`g`・`fig`・`be`・`e` などに git などの補完が効かない。コメント (「aliased ls needs…」) も効果と逆 | オプションを外す (エイリアスを展開して補完する既定に戻す) | あり |
| Z5 | `zsh/plugins.sh:1-9` | プラグインはコミットに固定する方針 ([ADR 0010](../adr/0010-fix-zsh-fzf-audit.md)) だが、zinit 本体は先頭のコミットを clone していて固定されていない | zinit を Nix で入れる、または clone 後に固定のコミットに切り替える | なし |
| Z6 | `zsh/exports.sh` | `EDITOR`・`LANG`・`XDG_*` が zshrc からしか読まれず、`zsh -c` などの非対話シェル (エディタや git の hook から呼ばれるもの) に届かない (PATH ではないので Z2 の path_helper の件とは別) | PATH 以外の export を zshenv に移す | 非対話シェルのみ |
| Z7 | `zsh/fzf.sh` (`__select_git_status_items` など) | zsh は変数を単語分割しないので、ループが 1 回しか回らず awk の行ごとの処理で偶然動いている。空白を含むパスや名前の変更 (`R a -> b`) で壊れる。fzf を取り消しても終了コードが 0 になる | `${(f)…}` で行ごとに回し、`git status --porcelain -z` を使う | ほぼなし |
| Z8 | `zsh/fzf.sh` (`__fkill`) | 既定のシグナルが SIGKILL (`-9`)。fzf を直接呼んでいて、ほかのコマンドと違い全画面になる | 既定を `-TERM` にし、呼び方をほかと揃える | あり |
| V3 | `nvim/lua/plugins/lsp.lua` | mason-tool-installer で入れた `rubocop`・`stylua` を、mason-lspconfig v2 の `automatic_enable` が LSP としても有効にしている (確認済み)。Ruby の診断が LSP と nvim-lint で二重に出て、Lua は lua_ls と stylua の両方で整形される | `automatic_enable = { exclude = { "rubocop", "stylua" } }`、conform に `lua = { "stylua" }` | あり |
| V4 | `nvim/lua/config/keymaps.lua:27-29` | `<Leader>fmt` が conform を通らず LSP で整形するので、保存時の整形 (prettier など) と結果が違う | `require("conform").format({ lsp_format = "fallback" })` | あり |
| V5 | auto-save・conform・`TrimTrailingWhitespace` の組み合わせ | 自動保存は `TextChanged` でも走るので、`x` や `dd` のたびに整形と行末の空白の削除が走る。行末の空白の削除は Markdown の行末 2 スペースの改行や diff の行末の空白も消す | 意図どおりならそのまま。避けるなら Markdown・diff を行末の空白の削除から外す | あり |
| N1 | `.github/workflows/ci.yml:60` | `DeterminateSystems/nix-installer-action@main` をブランチで参照していて、上流の変更がそのまま CI に入る | 現行の推奨の `DeterminateSystems/determinate-nix-action@v3` (v3.23.1) に替える | なし |
| N2 | `.github/workflows/ci.yml` | CI が `nix eval` だけで、自前のパッケージ (AquaSKK・Claude デスクトップ) をビルドしない。`bin/update-nix` が書き換えるハッシュの誤りや配布物の形式の変化を検出できない | 自前のパッケージを `nix build` するジョブを足す | なし |
| N3 | `bin/sync-deps:37` | Claude に許可する `Bash(curl -fsSL https://formulae.brew.sh/:*)` は前方一致なので、後ろに任意の引数 (別の URL・`-o` での書き込み) を足しても許可される。取得した JSON 経由のプロンプトインジェクションに弱い | curl の許可を外し、`bin/update-nix` の取得処理を呼ばせる | あり |
| N4 | `bootstrap.sh:56-57` | Determinate Nix のインストーラを、版を固定せず検証もせずに `curl \| sh` している | 版を固定した URL にする | なし |
| G2 | `git/config` | `transfer.fsckObjects` などの、取り込むオブジェクトの検査が無い | `[transfer] fsckObjects = true` | 不正なオブジェクトの取得が失敗する |
| T2 | `tmux/statuses.conf:1-9` | 色の変数 (`background=` など) が tmux の全体の環境変数に入り、全ペインのシェルに渡っている (確認済み) | `%hidden background="#2e2e2e"` の形にする | なし |
| T3 | `tmux/tmux.conf:52` | `prefix + Y` で、パスを単引用符の中に生のまま埋め込むため、`'` や `#` を含むパスで壊れる | `#{q:pane_current_path}` を使う | なし |
| T4 | `tmux/tmux.conf:7` | `history-limit 2000000` はペインごとの上限で、メモリの消費が大きい | 10〜20 万行にする | あり |
| C1 | `.claude/settings.json` (`statusLine`) | `xargs basename` が空白を含むディレクトリ名で壊れる。jq を 4 回起動している | jq 1 回で組み立て、`split("/") \| last` でディレクトリ名を取る | 小 |

## 陳腐化

| ID | 場所 | 内容 | 直し方 | 挙動 |
|---|---|---|---|---|
| Z9 | `zsh/fzf.sh` | `--extended` (以前から既定)、`setopt … 2>/dev/null` (昔の互換)、不要な `eval "$cmd"`、10 か所で重複する `FZF_DEFAULT_OPTS="--height …"` | 削除し、fzf 0.74 の `__fzf_defaults` で揃える | ほぼなし |
| Z10 | `zsh/completions.sh` | fzf-tab の README が勧める `zstyle ':completion:*' menu no` と、グループの見出しの設定が無い | 2 行を足す | 小 |
| V6 | (設定なし) | nvim 0.11 から診断の行内の表示 (`virtual_text`) が既定で無効になり、今は記号と下線だけ (確認済み) | `vim.diagnostic.config({ virtual_text = true, severity_sort = true })` | あり |
| V7 | `nvim/lua/config/lazy.lua:3-8` | lazy.nvim の導入の処理が古い書き方 (`vim.loop` の互換、clone の失敗を確かめない) | 公式の現行の書き方に合わせる | なし |
| T5 | `tmux/tmux.conf:28` | `escape-time 0`。tmux 3.5 以降の既定は 10ms で、遅い経路では Esc で始まる入力が分断されることがある | `10` にする | ほぼなし |
| T6 | `tmux/tmux.conf`・`tmux/scripts/copy-line` | `pbcopy` を 3 か所に書いている。tmux 3.2 以降は `copy-command` を 1 回設定すれば済む | `set -s copy-command pbcopy` | なし |
| T7 | `tmux/tmux.conf:1` | `unbind-key -n C-a` は、もともと割り当ての無いキーの解除。既定の `C-b` の prefix は残っている | 行を消し、`unbind C-b` を検討する | なし |
| C2 | `.claude/settings.json`・usage-hint | 2026-10-09 の監査の C2。ステータスラインと usage-hint の両方がコンテキストの使用率を出している | ステータスラインから外す | あり |
| O2 | `vscode/settings.json` | Copilot の古い設定・コマンド、言語 ID ではない `"md"`・`"mdx"`、保守の止まった拡張 (`bodil.prettier-toml`) | 現行の設定・拡張に置き換える | 小 |
| O3 | `ghostty/config:9` | Cmd+P を Super 付きのキー (`CSI 112;9u`) として送るが、tmux は Super を扱えず `extended-keys` も off なので、tmux の中の nvim には届かない可能性が高い (未確認) | tmux が中継できるキー (`Alt-p` など) にする | あり |

## 整理

| ID | 場所 | 内容 |
|---|---|---|
| Z11 | `zsh/common.sh:42-48` | 履歴の検索のコメントが `^P/^N` だが、実際の割り当ては `Alt-p/Alt-n` |
| Z12 | `zsh/common.sh`・`aliases.sh`・`langs/swift.sh`・`exports.sh` | 重複する `nolistbeep`、入っていない `colordiff`・`gsed` の分岐、組み込みの `where` を隠すエイリアス、効かない `TOOLCHAINS=swift`、無い gcloud の分岐 |
| Z13 | `zsh/tests` | fzf のコマンドの解析処理 (Z7 など) とウィンドウの一覧の整形にテストが無い |
| V8 | `nvim/lua/config/options.lua` | 使っていない `tags = "tags"` (既定より狭い)、既定と同じ `backup = false` |
| V9 | `keymaps.lua:2`・`nvim-tree.lua:6` | 実態と合わないコメント (リーダーを設定する場所、nvim-tree を常に表示) |
| V10 | `nvim/lua/plugins/lint.lua:68` | autocmd に augroup が無く、読み込み直すと重複する |
| V11 | `nvim/lua/plugins/completion.lua` | LuaSnip に jsregexp が無く、LSP のスニペットの一部の変換が効かない (`build = "make install_jsregexp"`) |
| V12 | `keymaps.lua:15` | `<C-w>o` を `:tabnew %` にしていて、標準の `:only` を潰している |
| N5 | `.github/workflows/ci.yml` | usage-hint のテストが CI に無い。zsh のテストを 1 つずつ書いているので、足したときに漏れる。`concurrency`・`timeout-minutes` が無い |
| N6 | `bootstrap.sh:30-45`・`install.sh` | Xcode Command Line Tools の待ち合わせが 2 か所にあり、方式も違う |
| N7 | `flake.nix` | 不要な `inherit system`・`home.username`・`home.homeDirectory`・`users.users.<名前>.name`・`programs.home-manager.enable`。`postActivation.text` の直接の代入 (`lib.mkAfter` にする)。`system.configurationRevision` が無い |
| N8 | `.gitignore` | `nix build` が作る `result` のリンクが入っていない |
| N9 | `.githooks/pre-commit` | adr-guard が無いと「command not found」だけで止まる。案内を出す |
| N10 | (メモ) | Command Line Tools が 14.3 (2023 年) と古く、リンカも古い。新しいビルドで失敗することがある (2026-10-11 に diesel で発生)。本人が更新する |
| G3 | `git/config` | 同じ定義のエイリアス (`lg` と `lgraph`、`cl` と `cia`)。`delete-merged-branches` が別の worktree で使っているブランチ (`+`) を除外していない |
| G4 | `git/config` | `difftool.prompt = false` と `mergetool.prompt = true` が不揃い (意図していれば問題なし) |
| G5 | (既提案) | `commit.verbose`・`rebase.autosquash`・`branch.sort`・`column.ui`・`push.followTags` などの便利な設定 |
| T8 | `tmux/tmux.conf:33-34` | `bind p`・`bind n` は既定と同じ |
| T9 | `tmux/tmux.conf` | prefix が `C-q` になった後も、既定の `C-b` の割り当て (`send-prefix`) が残っている |
| C3 | usage-hint の `format.ts:33` | `formatUsage` がテスト以外から使われていない。`tsconfig.json` が git の管理外の型定義を読むので、clone 直後は型検査が通らない |
| C4 | `.claude/settings.json` | `enabledPlugins` で skill-creator が重複 (`skill-creator@claude-plugins-official` と `example-skills` の中のもの) |
| O4 | `vscode/settings.json` | `<Leader> q` の割り当てが 2 つある |
| O5 | `karabiner/karabiner.json` | 使っていない空のプロファイル (`New profile`) |

## 問題が無かったもの

- **zsh:** キャッシュした `eval`、補完の初期化の順序と 1 日 1 回の検査、fzf-tab と遅延読み込みのプラグインの順序、git のプロンプト、`.gitignore` に従う補完、`ZDOTDIR` の条件付きの設定。テストは 4 つとも CI で実行している。
- **nvim:** 非推奨の API は使っていない (`:checkhealth vim.deprecated` も問題なし)。nvim-treesitter の main ブランチの使い方、flash・trouble・treesitter-context・which-key・telescope の設定、前回の位置の復元。
- **Nix:** nix-darwin・home-manager の警告は 0 件。入力の `follows`、`stateVersion` (上げると Docker などの場所が変わるので据え置きが正しい)、自前のパッケージの署名の保持。`install.sh` は POSIX sh として正しく、冪等。
- **git・tmux:** `zdiff3`・`histogram`・`rerere`・`pull.rebase` などは現行の推奨どおり。tmux 3.7c で設定がエラー無く読める。
- **Claude Code:** 広すぎる許可の設定は無い。adr-guard の hook は妥当。usage-hint はクラスを使っておらず、純粋な関数とテストに分かれている。
- **`bin/`:** `orch` の引用符・入力の検証・タイムアウトの扱いは堅実。小さなスクリプトも正しい。

## 調べた結果、当てはまらなかったもの

- `zsh/fzf.sh` の `__find_node_modules` が呼ぶ `find_node_packages` は「どこにも無い」と見えたが、`~/.cargo/bin` に入っている (故障ではない)。
