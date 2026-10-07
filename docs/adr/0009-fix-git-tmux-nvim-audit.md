# ADR 0009: 監査 (2026-10-07) の git / tmux / nvim 項目を是正する

- Status: Accepted
- Date: 2026-10-07
- 関連: docs/audit/2026-10-07-best-practices.md の G1〜G5, T1, B4, V1〜V6

## Context

監査で git / tmux / nvim に、壊れている設定・非推奨の設定・保守の止まった依存が見つかった。
本 ADR ではそれらの是正方針を決める。好みに関わるものは本人の回答に従う。

## Decision

### git
- `gitignore_global` は全リポジトリに効くため、「どのプロジェクトでもコミットしないもの」
  (OS・エディタのゴミ、依存のインストール先 `node_modules/` `/vendor/bundle/`、キャッシュ、ログ、
  `/tmp/*` `/log/*`) だけを残す。プロジェクトによってはコミットする設定ファイルやビルド成果物
  (`.config`、`config/*.yml`、`dist`、`.ruby-version`、`.python-version`、`target/`、`coverage`、`pkg` 等)
  は各リポジトリの `.gitignore` に任せる。
  - 依存やログまで外す案は、手元の 19 リポジトリで数万ファイルが見えるようになるため採らない
    (多くのリポジトリが自前の `.gitignore` を持たずにグローバル設定に頼っている)。
  - 採用案で新たに見えるようになるのは手元の 4 リポジトリ・少数のファイルに留まる。
- `gitconfig`:
  - `core.filemode = false` と `core.autocrlf = input` を削除し、git の既定に戻す。
  - `push.default = tracking` (非推奨の別名) をやめ、既定の `simple` に `push.autoSetupRemote = true` を足す。
  - rebase 設定の重複 (`branch.master.rebase`、`branch.autosetuprebase`) を削除し、`pull.rebase = true` に一本化する。
  - `merge.conflictstyle = zdiff3`、`merge.tool` / `diff.tool` を `nvimdiff` にする。
  - `fetch.prune`、`rerere.enabled`、`diff.algorithm = histogram`、`rebase.autoStash` を有効にする。
  - `delete-merged-branches` は main / master / develop を消さないようにする。
  - delta のリンク先 (`vscode://`) は好みの問題なので変えない。
- `.gitignore` の古いエントリを削除し、`tmux-*` を tmux のログファイルに限定する。
- `.gitmodules` の URL を HTTPS にする (clone に SSH 鍵を要らなくする)。

### tmux
- 分割と新規ウィンドウは今のペインのディレクトリで開く (`-c "#{pane_current_path}"`)。
- `tmux/segments/lan-ip` は bash の構文を使っているので shebang を `bash` にする。
- TPM はプラグインのバージョン固定に対応していないため、固定はしない。

### nvim
- nvim-treesitter を `main` ブランチに移行する。`main` は書き直し版で、ハイライトは
  `FileType` で `vim.treesitter.start()`、インデントは `indentexpr` で有効にする。
  パーサーのビルドに必要な `tree-sitter` CLI (0.26.1 以上、npm 不可) を
  `dependencies.md` と `flake.nix` に追加し、home-manager で適用する。
- mason / mason-lspconfig を移転先の `mason-org/` に変える。
- conform の非推奨オプション `lsp_fallback` を `lsp_format = "fallback"` にする。
- Comment.nvim を削除し、Neovim 標準のコメント機能 (`gc`) を使う。`<C-k>` の割り当ては維持する。
- telescope は止まっている `0.1.x` ブランチをやめ、最新リリース (`version = "*"`) を使う。
- windows.nvim (と依存の animation.nvim / middleclass) を focus.nvim に置き換える。
- monokai.nvim を monokai-pro.nvim (MIT) の `classic` フィルタに置き換える。
- 外部ツール (stylua / prettier / eslint_d) は mason-tool-installer で mason 経由で入れ、
  nvim-lint の JS/TS は `eslint_d` を使う。dotfiles 外の旧ツール (volta / rbenv) に依存しない。
  - rubocop も対象にする予定だったが、mise の Ruby (4.0.5) が削除済みの Homebrew の `gmp` に
    リンクしていて起動できず、gem でのインストールに失敗する。Ruby の修復は本 ADR の範囲外とし、
    直るまで rubocop は対象に含めない。
- Ghostty が Cmd+P を `<D-p>` で送るので、`<D-p>` にもコマンドパレットを割り当てる。
- 効果のないオプション指定、leader の二重設定、`vim.keymap.set` への `noremap` を削除する。

## Consequences

- 他リポジトリで、今まで global ignore で隠れていたファイルが untracked として見えるようになる。
- `core.filemode` が既定に戻るため、実行権限だけが違うファイルが差分として現れることがある。
- nvim の見た目 (配色・ウィンドウのリサイズのアニメーション) が少し変わる。
- nvim の rubocop は、Ruby が直るまで従来どおり PATH 上のもの (旧 rbenv) に頼る。
- treesitter のパーサーは tree-sitter CLI でローカルにビルドされるため、C コンパイラが必要になる。
