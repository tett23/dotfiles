# dotfiles ベストプラクティス監査 (2026-10-07)

調査範囲: 追跡ファイル約 100 個すべてと、実機での確認 (PATH、インストール状況、プラグインの最終コミット日など)。
修正はしていない。優先度は付けず、種類のタグのみ付ける。ID は優先度を決める際の参照用。

最終更新: 2026-10-07 (各項目の「状況」に対応状況を追記。凡例: ✅ 対応済み / 🔶 一部対応 / ⏸ 見送り / ⬜ 未対応)

- **故障**: 今まさに動いていない
- **リスク**: 事故やデータ消失につながりうる
- **陳腐化**: 古い・非推奨
- **整理**: 不要物や重複

## 1. シェル (zsh)

- **Z1 [故障]** `~/.zshenv` が存在しない `dotfiles/zshenv` を指すリンク切れ。`setup/install.sh` が `zshenv` と `exenv` をリンクしているが、どちらもリポジトリに無い。
  - 状況: ✅ 対応済み — zsh/zshenv を新設 (ADR 0010)
- **Z2 [リスク]** 環境変数と PATH をすべて `.zshrc` で設定しているため、対話シェル以外 (スクリプト、tmux の `#()`、エディタから起動したコマンド) には反映されない。本来は `.zshenv` / `.zprofile` に置く内容。
  - 状況: ⏸ 見送り — path_helper が PATH を並べ替えるため (ADR 0010)
- **Z3 [リスク]** `XDG_RUNTIME_DIR=~/.local/run` が XDG 仕様に反する。仕様では本人専用 (0700) でログアウト時に消える一時領域であるべきで、macOS では通常設定しない。
  - 状況: ⏸ 見送り — cc-socks / sbt が ~/.local/run を使っているため (ADR 0010)
- **Z4 [整理]** `~/dotfiles` という場所が複数箇所に固定で書かれている (`zshrc`、`MISE_TRUSTED_CONFIG_PATHS`、`tmux.conf`、`claude/settings.json` の `CLAUDE_CODE_PLUGIN_DIRS`)。`install.sh` は `DOTFILES` で clone 先を変えられるので、別の場所に入れると壊れる。
  - 状況: 🔶 一部対応 — zshrc / MISE_TRUSTED_CONFIG_PATHS は対応 (ADR 0010)。tmux.conf、claude/settings.json、flake.nix (dotfilesDirectory) に残る
- **Z5 [故障]** dotfiles の外から古いツールのディレクトリが PATH に混入している (`~/.volta`、`~/.rbenv/shims`、`~/.pyenv/shims`、`~/.bun`、`~/.deno`、`~/Library/pnpm`)。
  - `node` / `python3` / `ruby` が mise 版と旧ツール版の二重に解決される。
  - Neovim の `prettier` と `rubocop` はこの旧ディレクトリ経由でしか見つからない (クリーンな環境では見つからないことを確認)。
  - 状況: ✅ 対応済み — 旧ツールのディレクトリをゴミ箱に移した。nvim の rubocop は mason 版に切り替え (ADR 0015)
- **Z6 [陳腐化]** Homebrew の PATH を手で足している (`brew shellenv` を使っていない)。PATH の優先順位が「nix-profile → Homebrew → … → mise → `/etc/profiles/per-user`」で、Nix の home-manager の bin が後ろにある。
  - 状況: 🔶 一部対応 — Homebrew は廃止 (ADR 0012)。/etc/profiles/per-user の優先順位は使われるバイナリが変わるため見送り
- **Z7 [陳腐化]** 履歴の設定で `hist_ignore_space`、`extended_history`、`hist_reduce_blanks` が未設定。`HISTFILE` も XDG の場所ではなくホーム直下。
  - 状況: 🔶 一部対応 — extended_history のみ。HISTFILE の移動と hist_ignore_space / hist_reduce_blanks は見送り
- **Z8 [リスク]** `compinit -C` を常に付けているので、補完定義を追加しても dump が更新されず反映されないことがある。
  - 状況: ✅ 対応済み — 1 日 1 回だけ検査 (ADR 0010)
- **Z9 [リスク]** zinit がシェル起動時にネットワークから clone する。プラグインのバージョンも固定されていない。fast-syntax-highlighting が `compinit` より前に読み込まれている (公式推奨は後)。
  - 状況: ✅ 対応済み — コミット固定・読み込み順・遅延読み込み (ADR 0010, 0011)
- **Z10 [陳腐化]** `prompt.sh` に不要な処理が残っている。
  - `is-at-least 4.3.7` という古いバージョン分岐
  - vcs_info で使っていない svn / hg / bzr の有効化
  - プロンプトのたびに `git stash list` を実行する fork
  - 状況: ✅ 対応済み — git status 1 回で表示を作る (ADR 0010, 0011)
- **Z11 [整理]** 中身のないファイルを読み込んでいる。`modern-commands.sh` は全行コメント、`anyenv.sh` はコメントのみ。`langs/scala.sh` は存在確認なしで PATH を追加している。
  - 状況: ✅ 対応済み — ADR 0010
- **Z12 [故障]** `fzf.sh` に動かない設定がある。
  - `__gh_pr_branch` が廃止され未インストールの `hub` を使っている。
  - `bindkey "^,"` は端末から送れないキー。
  - 状況: 🔶 一部対応 — hub は gh に置換 (ADR 0010)。^, の割り当て先は本人が決める
- **Z13 [整理]** `aliases.sh` の整理の余地。
  - `[[ -x `which …` ]]` という古い書き方。
  - `colordiff` と `gsed` は未インストールで分岐が死んでいる。
  - Nix の `sed` がすでに GNU 版なので `sed`→`gsed` の alias は不要。
  - 状況: ✅ 対応済み — ADR 0010

## 2. bin / スクリプト

- **B1 [リスク]** `bin/docker-sh` と `bin/figrm` は shebang が `#!/bin/sh` なのに bash 専用の書き方 (`${@:2}`) を使っている。`$1` もクォートされていない。
  - 状況: ✅ 対応済み — shebang を bash にし、引数をクォート (ADR 0014)
- **B2 [故障]** `bin/rtouch` は POSIX sh で不正な書き方をしている (`exit -1`、`local`、クォートなし)。
  - 状況: ✅ 対応済み — POSIX sh として書き直し (ADR 0014)
- **B3 [故障/整理]** `bin/short-pwd` は shebang が `#/bin/env` (`!` 抜け) で壊れている。プロンプトと tmux は代替済み (ADR 0007) で、今は使われていない。
  - 状況: ✅ 対応済み — VSCode のターミナル設定が使っているので削除せず、shebang だけ修正 (ADR 0014)
- **B4 [リスク]** `tmux/segments/lan-ip` も `#!/bin/sh` なのに `[[ ]]`、配列、`read -ra`、`<<<` を使っている。macOS の `/bin/sh` が bash なのでたまたま動いているだけ。
  - 状況: ✅ 対応済み — shebang を bash に (ADR 0009)
- **B5 [陳腐化]** `bin/send-to-kindle` に古い書き方が残っている。
  - `deno.land/std@0.224.0` を使っている (JSR の `@std/dotenv` が推奨)。
  - `-A` で全権限を与えている。
  - カレントディレクトリの `.env` に依存している。
  - 状況: 🔶 一部対応 — dotenv を JSR の @std/dotenv に置き換え (ADR 0014)。権限と .env の場所は docs/audit/2026-10-07-breaking-changes.md を参照
- **B6 [陳腐化]** `bin/orch` の、モデルの別名から実際のモデル ID への対応表が古い (`claude-opus-4-8`、`claude-fable-5`、`claude-sonnet-5`、推定値の `gpt-5.6-sol`)。
  - 状況: ⬜ 未対応 — 使うモデルが変わるため見送り。docs/audit/2026-10-07-breaking-changes.md を参照

## 3. インストール / ルート直下

- **I1 [故障/整理]** `clean_install.sh` は旧手順で壊れている (Homebrew の行のクォートが閉じていない、廃止されたキーサーバー `keys.gnupg.net`、Intel Mac のパス、volta、RVM の鍵)。`install.sh` で代替済み。
  - 状況: ✅ 対応済み — 削除 (ADR 0014)
- **I2 [整理]** 使われていないファイル: `setup/install_curl.sh`、`setup/detect_package_manager.sh`、空の `docs/ask.md`、ルートの空の `node_modules/`。
  - 状況: ✅ 対応済み — 削除 (ADR 0014)
- **I3 [リスク]** `setup/install.sh` の書き方に危険がある。
  - `ln -nsf` で既存の実ファイルをバックアップなしで上書きする。
  - 変数がクォートされておらず、shebang も無い。
  - `CLAUDE.md` を `~/CLAUDE.md` にリンクしているが、Claude Code のユーザー設定の正しい場所は `~/.claude/CLAUDE.md`。現在 `~/CLAUDE.md` は存在しない。
  - 状況: ✅ 対応済み — setup/install.sh を廃止し、リンクは home-manager で張る。exenv と ~/CLAUDE.md のリンクはやめた (ADR 0015)
- **I4 [整理]** home-manager があるのに、dotfiles のリンクは `setup/install.sh` で張っている。同じ dotfiles を 2 つの仕組みで管理している。
  - 状況: ✅ 対応済み — リンクを home-manager に移し、単体の home-manager をやめて nix-darwin に一本化 (ADR 0015)

## 4. git

- **G1 [リスク]** `gitignore_global` に特定プロジェクト向けのパターンが全リポジトリ共通の設定として入っている。他のリポジトリで必要なファイルを黙って無視する恐れがある。
  - 例: `.config`、`config/*.yml`、`dist`、`.ruby-version`、`.python-version`、`/log/*`、`/tmp/*`、`target/`、`.cache`、`classes/`、`.settings`、`packages/backend/python/fit/build/`
  - `vender/bundle .ruby-lsp/` は 2 つのパターンが 1 行になった誤記。
  - 状況: ✅ 対応済み — ADR 0009
- **G2 [陳腐化]** `gitconfig` に古い・冗長な設定がある。
  - `push.default = tracking` は非推奨の別名。
  - `merge.conflictstyle` は `diff3` より `zdiff3` が推奨。
  - rebase 関連 (`branch.master.rebase`、`autosetuprebase`、`pull.rebase`) が重複。
  - `merge.tool` が `vimdiff` でエディタの nvim と合っていない。
  - delta のリンク先が `vscode://`。
  - 状況: 🔶 一部対応 — delta のリンク先 (vscode://) は好みのため変更せず。他は ADR 0009 で対応
- **G3 [リスク]** グローバル設定の `core.filemode = false` で実行権限の変更を全リポジトリで無視している。`delete-merged-branches` は今いるブランチ以外なら main / master も削除しうる。
  - 状況: ✅ 対応済み — ADR 0009
- **G4 [陳腐化]** 現在よく使われる設定 (`fetch.prune`、`rerere.enabled`、`diff.algorithm=histogram`、`rebase.autoStash` など) が入っていない。
  - 状況: ✅ 対応済み — ADR 0009
- **G5 [陳腐化]** `.gitignore` に古いエントリ (`vim/plugged` など) と広すぎる `tmux-*` がある。tmux-plugins の submodule URL が SSH なので、`install.sh` で HTTPS に読み替える回避策が要っている。
  - 状況: ✅ 対応済み — ADR 0009

## 5. Nix / Homebrew / mise

- **N1 [リスク]** `homebrew.onActivation.cleanup = "zap"` はリストに無いアプリをアプリのデータごと削除する。Homebrew に残っている `pkgconf` と `sdl2-compat` は次の適用で消える。
  - 状況: ✅ 対応済み — Homebrew を廃止 (ADR 0012)
- **N2 [故障]** sync-deps スキルには「`homebrew.onActivation` が upgrade を担う」とあるが、flake に `upgrade` も `autoUpdate` も設定されていない。Cask は更新されない。
  - 状況: ✅ 対応済み — Homebrew を廃止し、更新は bin/update-nix で行う (ADR 0012)
- **N3 [リスク]** `flake.lock` の所有者が `root` (sudo で書かれたため)。一般ユーザーでの `nix flake update` が失敗する恐れがある。flake の入力は 2026-06 時点のまま約 4 か月更新されていない。
  - 状況: ✅ 対応済み — flake.lock の所有者を戻し、bin/update-nix で最新化 (ADR 0012)
- **N4 [陳腐化]** flake の入力元 `github:LnL7/nix-darwin` は `nix-darwin/nix-darwin` に移転している。`nixpkgs_2` は claude-code の flake が自前の nixpkgs を持っているための重複。
  - 状況: ✅ 対応済み — 入力元を nix-darwin/nix-darwin に変更 (システムのビルド結果は同一)。claude-code の nixpkgs を follows でそろえた (ADR 0014)
- **N5 [整理]** 同じツールが二重に入っている。
  - claude: Nix 版 2.1.168 と公式インストーラ版 2.1.289。Nix 版は使われていない。
  - codex: Homebrew の Cask 版と Nix 版。
  - VSCode と Karabiner-Elements は手動インストールで宣言的な管理の外。
  - 状況: 🔶 一部対応 — codex の二重と VSCode の手動管理は解消 (ADR 0012)。claude CLI は公式インストーラ版と Nix 版の二重が残る
- **N6 [リスク]** mise の言語とツールがすべて `latest` でロックファイルも無い (本人の方針どおりだが再現性の面で記録)。
  - 状況: ⏸ 見送り — 本人の方針

## 6. Neovim (0.12.2)

- **V1 [陳腐化]** nvim-treesitter が `master` に固定されている。upstream の既定ブランチは `main` で、`master` は 2026-03-23 で止まっている。
  - 状況: ✅ 対応済み — ADR 0009
- **V2 [陳腐化]** 保守されていない、または古いプラグイン。
  - windows.nvim / animation.nvim / middleclass (2022〜2023 年で停止)
  - monokai.nvim (2023 年)
  - telescope の `0.1.x` (2024-05)
  - barbar (2024-07)
  - Comment.nvim (2024-06)。Neovim 0.10 以降はコメント機能 (`gc`) が標準で入っている。
  - 状況: ✅ 対応済み — ADR 0009
- **V3 [陳腐化]** mason が `williamboman/` から `mason-org/` に移転している。conform の `lsp_fallback` は非推奨で `lsp_format = "fallback"` が推奨。
  - 状況: ✅ 対応済み — ADR 0009
- **V4 [故障]** 外部ツールが足りない。
  - nvim-lint の `eslint` が未インストール。
  - `stylua.toml` はあるのに `stylua` が無い。
  - `prettier` と `rubocop` は Z5 の旧ディレクトリ経由でしか見つからない。
  - 状況: ✅ 対応済み — stylua / prettier / eslint_d / rubocop を mason で導入 (ADR 0009, 0015)
- **V5 [故障]** Ghostty が Cmd+P を `<D-p>` として送る設定だが、nvim 側は `<C-p>` にしか割り当てていない。コメントに書かれた意図と実装が食い違っている。
  - 状況: ✅ 対応済み — ADR 0009
- **V6 [整理]** 効果の無い設定。
  - `encoding`、`wildmenu`、`incsearch` など nvim では最初から有効なオプションの指定
  - leader の二重設定
  - `vim.keymap.set` への `noremap` 指定
  - 状況: ✅ 対応済み — ADR 0009

## 7. tmux

- **T1 [陳腐化]** 分割したペインが今いるディレクトリではなくセッションの開始ディレクトリで開く (`-c "#{pane_current_path}"` が無い)。TPM のプラグインはバージョンが固定されておらず、2022〜2024 年のまま更新されていない。
  - 状況: 🔶 一部対応 — pane_current_path は対応 (ADR 0009)。TPM はバージョン固定に対応していない

## 8. Claude Code

- **C1 [リスク]** `claude/settings.json` は全リポジトリに効くユーザー設定だが、その `autoMode.environment` に別リポジトリ (golem) 向けの説明が入っている。
  - 内容は「リモートの無いローカル専用リポジトリなので非公開扱い」というもの。
  - これを GitHub で公開されている dotfiles を含むすべてのリポジトリに当てはめている。auto mode の判断材料として誤っている。
  - 状況: ⬜ 未対応 — auto mode の判断が変わるため見送り。docs/audit/2026-10-07-breaking-changes.md を参照
- **C2 [整理]** `statusLine` の表示内容が usage-hint mod と一部重なっている (ctx)。
  - 状況: ⬜ 未対応 — 表示が変わるため見送り。docs/audit/2026-10-07-breaking-changes.md を参照
- **C3 [リスク]** CI が無い。shellcheck、stylua、`nix flake check`、`claude plugin test` のどれも自動で実行されない。mod の `tsconfig.json` が継承している型定義ファイルは git で無視されているので、新しく clone した環境ではエディタの型チェックが効かない。
  - 状況: 🔶 一部対応 — GitHub Actions の CI を追加 (ADR 0014)。mod の型定義は docs/audit/2026-10-07-breaking-changes.md を参照

## 9. その他

- **O1 [陳腐化]** `rubocop.yml` の `TargetRubyVersion: 2.5` はサポートが終わったバージョンで、現行の RuboCop が対象にする最小バージョンより古い。
  - 状況: ✅ 対応済み — TargetRubyVersion の指定を削除 (ADR 0015)
- **O2 [リスク]** VSCode のグローバル設定で既定のフォーマッタが `denoland.vscode-deno` になっており、Node のプロジェクトでも TypeScript を deno で整形してしまう。`go.alternateTools` の `go-langserver` も古い設定。
  - 状況: 🔶 一部対応 — go-langserver の指定を削除 (ADR 0014)。既定のフォーマッタは docs/audit/2026-10-07-breaking-changes.md を参照

## 確認して問題なかったもの

- zsh の起動時間は 0.18〜0.19 秒で遅くない。
- `lazy-lock.json` は git で管理されている。
- Karabiner は設定ディレクトリごとリンクしており、公式推奨の方法どおり。
- 追跡されているファイルに秘密情報らしき文字列は無かった。

## 10. 移行後に見つかったもの

- **M1 [整理]** `/opt/homebrew` に Homebrew の残骸 (275 MB) がある。`brew` コマンドは無く、公式アンインストーラが消し残したもの。
  - 状況: ✅ 対応済み — 本人が手動で削除
- **M2 [整理]** 手動で入れた VSCode 1.138 (`/Applications/Visual Studio Code.app`) が、Nix 版 (`/Applications/Nix Apps`) と並んで残っている。
  - 状況: ✅ 対応済み — 手動版をゴミ箱に移し、/usr/local/bin/code を削除 (ADR 0015)

## 対応状況のまとめ

- ✅ 対応済み: Z1, Z5, Z8〜Z11, Z13, B1〜B4, I1〜I4, G1, G3〜G5, N1〜N4, V1〜V6, O1, M1, M2
- 🔶 一部対応: Z4, Z6, Z7, Z12, B5, G2, N5, T1, C3, O2
- ⏸ 見送り: Z2, Z3, N6
- ⬜ 未対応 (直すと挙動が変わる。docs/audit/2026-10-07-breaking-changes.md を参照): B6, C1, C2

関連する ADR: 0009 (git / tmux / nvim)、0010 (zsh / fzf)、0011 (zsh の高速化)、0012 (Homebrew の廃止)、0013 (dependencies.md からの設定生成)、0014 (挙動を変えない残りの是正)、0015 (挙動が変わる項目の是正)。

## 判断できなかったこと

- Z5 の旧ディレクトリが PATH に入る経路は dotfiles の外にある。デスクトップアプリが引き継いでいるログインシェルの環境や launchd が考えられるが、特定できていない。
- 追記: Ruby の故障の原因は、mise のビルド済み Ruby が Homebrew の `gmp` にリンクしていたことだった。最新の mise で入る Ruby 4.0.7 では解消した。
- `nix flake check` は時間がかかるため実行していない。今の入力で flake が問題なく評価できるかは未確認。
  - 追記: その後、最新の入力で `nix build .#darwinConfigurations.dione.system` が通ることを確認した (ADR 0012)。
- VSCode の約 100 項目の設定と Karabiner の各ルールは、内容が今も妥当かまでは詳しく検証していない。
- `orch` のモデル ID が今も有効かは、実際に呼び出して確かめていない。

## 考察

大きな傾向は 3 つある。

- **移行の取り残し**: Nix・mise・Neovim の Lua 化という移行を進めた結果、旧方式の残骸 (volta / rbenv / pyenv、clean_install.sh、short-pwd、zshenv のリンク) があちこちに残っている。Z5・V4 のように実際の故障の原因にもなっている。
- **二重管理**: dotfiles のリンクは `setup/install.sh` と home-manager、ツールは Nix・Homebrew・mise・公式インストーラという二重管理になっており、どれが正なのかが曖昧 (I4・N5)。
- **影響範囲の広い設定**: `gitignore_global`、`core.filemode`、`autoMode.environment`、VSCode の既定フォーマッタは、このリポジトリだけでなく全プロジェクトに効く。直したときの効果が大きい反面、気づきにくい。
