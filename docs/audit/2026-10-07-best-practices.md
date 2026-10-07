# dotfiles ベストプラクティス監査 (2026-10-07)

調査範囲: 追跡ファイル約 100 個すべてと、実機での確認 (PATH、インストール状況、プラグインの最終コミット日など)。
修正はしていない。優先度は付けず、種類のタグのみ付ける。ID は優先度を決める際の参照用。

- **故障**: 今まさに動いていない
- **リスク**: 事故やデータ消失につながりうる
- **陳腐化**: 古い・非推奨
- **整理**: 不要物や重複

## 1. シェル (zsh)

- **Z1 [故障]** `~/.zshenv` が存在しない `dotfiles/zshenv` を指すリンク切れ。`setup/install.sh` が `zshenv` と `exenv` をリンクしているが、どちらもリポジトリに無い。
- **Z2 [リスク]** 環境変数と PATH をすべて `.zshrc` で設定しているため、対話シェル以外 (スクリプト、tmux の `#()`、エディタから起動したコマンド) には反映されない。本来は `.zshenv` / `.zprofile` に置く内容。
- **Z3 [リスク]** `XDG_RUNTIME_DIR=~/.local/run` が XDG 仕様に反する。仕様では本人専用 (0700) でログアウト時に消える一時領域であるべきで、macOS では通常設定しない。
- **Z4 [整理]** `~/dotfiles` という場所が複数箇所に固定で書かれている (`zshrc`、`MISE_TRUSTED_CONFIG_PATHS`、`tmux.conf`、`claude/settings.json` の `CLAUDE_CODE_PLUGIN_DIRS`)。`install.sh` は `DOTFILES` で clone 先を変えられるので、別の場所に入れると壊れる。
- **Z5 [故障]** dotfiles の外から古いツールのディレクトリが PATH に混入している (`~/.volta`、`~/.rbenv/shims`、`~/.pyenv/shims`、`~/.bun`、`~/.deno`、`~/Library/pnpm`)。
  - `node` / `python3` / `ruby` が mise 版と旧ツール版の二重に解決される。
  - Neovim の `prettier` と `rubocop` はこの旧ディレクトリ経由でしか見つからない (クリーンな環境では見つからないことを確認)。
- **Z6 [陳腐化]** Homebrew の PATH を手で足している (`brew shellenv` を使っていない)。PATH の優先順位が「nix-profile → Homebrew → … → mise → `/etc/profiles/per-user`」で、Nix の home-manager の bin が後ろにある。
- **Z7 [陳腐化]** 履歴の設定で `hist_ignore_space`、`extended_history`、`hist_reduce_blanks` が未設定。`HISTFILE` も XDG の場所ではなくホーム直下。
- **Z8 [リスク]** `compinit -C` を常に付けているので、補完定義を追加しても dump が更新されず反映されないことがある。
- **Z9 [リスク]** zinit がシェル起動時にネットワークから clone する。プラグインのバージョンも固定されていない。fast-syntax-highlighting が `compinit` より前に読み込まれている (公式推奨は後)。
- **Z10 [陳腐化]** `prompt.sh` に不要な処理が残っている。
  - `is-at-least 4.3.7` という古いバージョン分岐
  - vcs_info で使っていない svn / hg / bzr の有効化
  - プロンプトのたびに `git stash list` を実行する fork
- **Z11 [整理]** 中身のないファイルを読み込んでいる。`modern-commands.sh` は全行コメント、`anyenv.sh` はコメントのみ。`langs/scala.sh` は存在確認なしで PATH を追加している。
- **Z12 [故障]** `fzf.sh` に動かない設定がある。
  - `__gh_pr_branch` が廃止され未インストールの `hub` を使っている。
  - `bindkey "^,"` は端末から送れないキー。
- **Z13 [整理]** `aliases.sh` の整理の余地。
  - `[[ -x `which …` ]]` という古い書き方。
  - `colordiff` と `gsed` は未インストールで分岐が死んでいる。
  - Nix の `sed` がすでに GNU 版なので `sed`→`gsed` の alias は不要。

## 2. bin / スクリプト

- **B1 [リスク]** `bin/docker-sh` と `bin/figrm` は shebang が `#!/bin/sh` なのに bash 専用の書き方 (`${@:2}`) を使っている。`$1` もクォートされていない。
- **B2 [故障]** `bin/rtouch` は POSIX sh で不正な書き方をしている (`exit -1`、`local`、クォートなし)。
- **B3 [故障/整理]** `bin/short-pwd` は shebang が `#/bin/env` (`!` 抜け) で壊れている。プロンプトと tmux は代替済み (ADR 0007) で、今は使われていない。
- **B4 [リスク]** `tmux/segments/lan-ip` も `#!/bin/sh` なのに `[[ ]]`、配列、`read -ra`、`<<<` を使っている。macOS の `/bin/sh` が bash なのでたまたま動いているだけ。
- **B5 [陳腐化]** `bin/send-to-kindle` に古い書き方が残っている。
  - `deno.land/std@0.224.0` を使っている (JSR の `@std/dotenv` が推奨)。
  - `-A` で全権限を与えている。
  - カレントディレクトリの `.env` に依存している。
- **B6 [陳腐化]** `bin/orch` の、モデルの別名から実際のモデル ID への対応表が古い (`claude-opus-4-8`、`claude-fable-5`、`claude-sonnet-5`、推定値の `gpt-5.6-sol`)。

## 3. インストール / ルート直下

- **I1 [故障/整理]** `clean_install.sh` は旧手順で壊れている (Homebrew の行のクォートが閉じていない、廃止されたキーサーバー `keys.gnupg.net`、Intel Mac のパス、volta、RVM の鍵)。`install.sh` で代替済み。
- **I2 [整理]** 使われていないファイル: `setup/install_curl.sh`、`setup/detect_package_manager.sh`、空の `docs/ask.md`、ルートの空の `node_modules/`。
- **I3 [リスク]** `setup/install.sh` の書き方に危険がある。
  - `ln -nsf` で既存の実ファイルをバックアップなしで上書きする。
  - 変数がクォートされておらず、shebang も無い。
  - `CLAUDE.md` を `~/CLAUDE.md` にリンクしているが、Claude Code のユーザー設定の正しい場所は `~/.claude/CLAUDE.md`。現在 `~/CLAUDE.md` は存在しない。
- **I4 [整理]** home-manager があるのに、dotfiles のリンクは `setup/install.sh` で張っている。同じ dotfiles を 2 つの仕組みで管理している。

## 4. git

- **G1 [リスク]** `gitignore_global` に特定プロジェクト向けのパターンが全リポジトリ共通の設定として入っている。他のリポジトリで必要なファイルを黙って無視する恐れがある。
  - 例: `.config`、`config/*.yml`、`dist`、`.ruby-version`、`.python-version`、`/log/*`、`/tmp/*`、`target/`、`.cache`、`classes/`、`.settings`、`packages/backend/python/fit/build/`
  - `vender/bundle .ruby-lsp/` は 2 つのパターンが 1 行になった誤記。
- **G2 [陳腐化]** `gitconfig` に古い・冗長な設定がある。
  - `push.default = tracking` は非推奨の別名。
  - `merge.conflictstyle` は `diff3` より `zdiff3` が推奨。
  - rebase 関連 (`branch.master.rebase`、`autosetuprebase`、`pull.rebase`) が重複。
  - `merge.tool` が `vimdiff` でエディタの nvim と合っていない。
  - delta のリンク先が `vscode://`。
- **G3 [リスク]** グローバル設定の `core.filemode = false` で実行権限の変更を全リポジトリで無視している。`delete-merged-branches` は今いるブランチ以外なら main / master も削除しうる。
- **G4 [陳腐化]** 現在よく使われる設定 (`fetch.prune`、`rerere.enabled`、`diff.algorithm=histogram`、`rebase.autoStash` など) が入っていない。
- **G5 [陳腐化]** `.gitignore` に古いエントリ (`vim/plugged` など) と広すぎる `tmux-*` がある。tmux-plugins の submodule URL が SSH なので、`install.sh` で HTTPS に読み替える回避策が要っている。

## 5. Nix / Homebrew / mise

- **N1 [リスク]** `homebrew.onActivation.cleanup = "zap"` はリストに無いアプリをアプリのデータごと削除する。Homebrew に残っている `pkgconf` と `sdl2-compat` は次の適用で消える。
- **N2 [故障]** sync-deps スキルには「`homebrew.onActivation` が upgrade を担う」とあるが、flake に `upgrade` も `autoUpdate` も設定されていない。Cask は更新されない。
- **N3 [リスク]** `flake.lock` の所有者が `root` (sudo で書かれたため)。一般ユーザーでの `nix flake update` が失敗する恐れがある。flake の入力は 2026-06 時点のまま約 4 か月更新されていない。
- **N4 [陳腐化]** flake の入力元 `github:LnL7/nix-darwin` は `nix-darwin/nix-darwin` に移転している。`nixpkgs_2` は claude-code の flake が自前の nixpkgs を持っているための重複。
- **N5 [整理]** 同じツールが二重に入っている。
  - claude: Nix 版 2.1.168 と公式インストーラ版 2.1.289。Nix 版は使われていない。
  - codex: Homebrew の Cask 版と Nix 版。
  - VSCode と Karabiner-Elements は手動インストールで宣言的な管理の外。
- **N6 [リスク]** mise の言語とツールがすべて `latest` でロックファイルも無い (本人の方針どおりだが再現性の面で記録)。

## 6. Neovim (0.12.2)

- **V1 [陳腐化]** nvim-treesitter が `master` に固定されている。upstream の既定ブランチは `main` で、`master` は 2026-03-23 で止まっている。
- **V2 [陳腐化]** 保守されていない、または古いプラグイン。
  - windows.nvim / animation.nvim / middleclass (2022〜2023 年で停止)
  - monokai.nvim (2023 年)
  - telescope の `0.1.x` (2024-05)
  - barbar (2024-07)
  - Comment.nvim (2024-06)。Neovim 0.10 以降はコメント機能 (`gc`) が標準で入っている。
- **V3 [陳腐化]** mason が `williamboman/` から `mason-org/` に移転している。conform の `lsp_fallback` は非推奨で `lsp_format = "fallback"` が推奨。
- **V4 [故障]** 外部ツールが足りない。
  - nvim-lint の `eslint` が未インストール。
  - `stylua.toml` はあるのに `stylua` が無い。
  - `prettier` と `rubocop` は Z5 の旧ディレクトリ経由でしか見つからない。
- **V5 [故障]** Ghostty が Cmd+P を `<D-p>` として送る設定だが、nvim 側は `<C-p>` にしか割り当てていない。コメントに書かれた意図と実装が食い違っている。
- **V6 [整理]** 効果の無い設定。
  - `encoding`、`wildmenu`、`incsearch` など nvim では最初から有効なオプションの指定
  - leader の二重設定
  - `vim.keymap.set` への `noremap` 指定

## 7. tmux

- **T1 [陳腐化]** 分割したペインが今いるディレクトリではなくセッションの開始ディレクトリで開く (`-c "#{pane_current_path}"` が無い)。TPM のプラグインはバージョンが固定されておらず、2022〜2024 年のまま更新されていない。

## 8. Claude Code

- **C1 [リスク]** `claude/settings.json` は全リポジトリに効くユーザー設定だが、その `autoMode.environment` に別リポジトリ (golem) 向けの説明が入っている。
  - 内容は「リモートの無いローカル専用リポジトリなので非公開扱い」というもの。
  - これを GitHub で公開されている dotfiles を含むすべてのリポジトリに当てはめている。auto mode の判断材料として誤っている。
- **C2 [整理]** `statusLine` の表示内容が usage-hint mod と一部重なっている (ctx)。
- **C3 [リスク]** CI が無い。shellcheck、stylua、`nix flake check`、`claude plugin test` のどれも自動で実行されない。mod の `tsconfig.json` が継承している型定義ファイルは git で無視されているので、新しく clone した環境ではエディタの型チェックが効かない。

## 9. その他

- **O1 [陳腐化]** `rubocop.yml` の `TargetRubyVersion: 2.5` はサポートが終わったバージョンで、現行の RuboCop が対象にする最小バージョンより古い。
- **O2 [リスク]** VSCode のグローバル設定で既定のフォーマッタが `denoland.vscode-deno` になっており、Node のプロジェクトでも TypeScript を deno で整形してしまう。`go.alternateTools` の `go-langserver` も古い設定。

## 確認して問題なかったもの

- zsh の起動時間は 0.18〜0.19 秒で遅くない。
- `lazy-lock.json` は git で管理されている。
- Karabiner は設定ディレクトリごとリンクしており、公式推奨の方法どおり。
- 追跡されているファイルに秘密情報らしき文字列は無かった。

## 判断できなかったこと

- Z5 の旧ディレクトリが PATH に入る経路は dotfiles の外にある。デスクトップアプリが引き継いでいるログインシェルの環境や launchd が考えられるが、特定できていない。
- `nix flake check` は時間がかかるため実行していない。今の入力で flake が問題なく評価できるかは未確認。
- VSCode の約 100 項目の設定と Karabiner の各ルールは、内容が今も妥当かまでは詳しく検証していない。
- `orch` のモデル ID が今も有効かは、実際に呼び出して確かめていない。

## 考察

大きな傾向は 3 つある。

- **移行の取り残し**: Nix・mise・Neovim の Lua 化という移行を進めた結果、旧方式の残骸 (volta / rbenv / pyenv、clean_install.sh、short-pwd、zshenv のリンク) があちこちに残っている。Z5・V4 のように実際の故障の原因にもなっている。
- **二重管理**: dotfiles のリンクは `setup/install.sh` と home-manager、ツールは Nix・Homebrew・mise・公式インストーラという二重管理になっており、どれが正なのかが曖昧 (I4・N5)。
- **影響範囲の広い設定**: `gitignore_global`、`core.filemode`、`autoMode.environment`、VSCode の既定フォーマッタは、このリポジトリだけでなく全プロジェクトに効く。直したときの効果が大きい反面、気づきにくい。
