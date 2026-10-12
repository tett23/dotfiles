# ADR 0057: 改善案 (2026-10-13) の残りを直し、fzf の履歴検索のプレビュー・bat-extras・eza のオプションを入れる

ステータス: 採択

## 文脈

[dotfiles の改善案 (2026-10-13)](../audit/2026-10-13-improvements.md) のうち、[ADR 0055](0055-improvements-2026-10-13.md)・[0056](0056-remove-old-ghcup-and-stack.md)
の後に残った項目から、本人が G3・G4・C1・C2・O4・Z12 を直すこと、「提案したが入れていない便利な設定」から fzf の履歴検索の
プレビュー・bat-extras・eza のオプションを入れることを決めた。O3 (Ghostty の `Cmd+P` が tmux の中の nvim に届くか) は、
ADR 0055 の `extended-keys` の後に本人が届くことを確かめた。I10 (adr-guard) は本人が adr-guard のリポジトリで扱う。
fzf の `Alt-C` は使っていないので扱わない。

調べた結果は次のとおり。

- **G3** `git/config` に同じ働きのエイリアスがある。`lg` と `lgraph` は同じ定義。`cl` (`commit -av`) と `cia` (`commit -a`) は、
  ADR 0055 で `commit.verbose` を有効にしたので同じ働きになった。本人は `cia` を残すことにした。
- **G4** `difftool.prompt` は `false`、`mergetool.prompt` は `true` で揃っていない。
- **C1** Claude Code のステータスライン (`.claude/settings.json` の `statusLine`) は、ディレクトリ名を `xargs basename` で取るので、
  空白や引用符を含むディレクトリ名で壊れる。jq も 4 回起動している。
- **C2** ステータスラインと usage-hint ([ADR 0004](0004-usage-hint-mod.md)) の両方が、コンテキストの使用率を出している。
- **O4** VSCode (VSCodeVim) の `<Leader> q` に `:q` と `editor.action.quickFix` の 2 つを割り当てている。VSCodeVim は同じキーの
  2 つ目以降の割り当てを使わないので、`:q` だけが効いている。
- **Z12 (残り)** `zsh/common.sh` の `setopt nolistbeep` は、同じファイルの `setopt no_beep` (すべてのビープを止める) に含まれる。
  `zsh/aliases.sh` の `alias where="command -v"` は、zsh の組み込みの `where` (エイリアス・関数・PATH のすべての候補を出す) を隠している。
- **fzf の履歴検索 (`Ctrl-R`)** fzf 0.74 の zsh の履歴検索は、候補を「番号 + タブ + コマンド」の形で出し、複数行のコマンドは
  2 行目以降を「タブ + 続き」にする。プレビューは `FZF_CTRL_R_OPTS` で足せる。長いコマンドや複数行のコマンドは、一覧では
  途中までしか見えない。fzf の README の例はプレビューの切り替えに `Ctrl-/` を使うが、Ghostty が使っているので使えない。
  `Ctrl-O` は fzf・tmux・Ghostty のどれも割り当てていない (zsh の `Ctrl-O` は fzf の外の割り当てで、fzf の中では関係しない)。
- **bat-extras** nixpkgs の `bat-extras` に、`batgrep` (ripgrep の結果を bat で色付きで出す)・`batdiff` (git の差分を bat で出す)・
  `batman`・`batpipe`・`batwatch`・`prettybat` がある。
- **eza** 0.23.5。`--git-ignore` は `.gitignore` で除外したものを一覧から外す。`--hyperlink` はファイル名を端末のリンク
  (OSC 8) にし、Ghostty では `Cmd` を押しながらクリックすると開ける。tmux の中では、外側の端末がリンクに対応していることを
  `terminal-features` の `hyperlinks` で宣言しないとリンクが外れる。

## 実装すること

| 案 | 変更 |
|---|---|
| G3 | `git/config` のエイリアス `lgraph` と `cl` を消す (`lg`・`cia` を残す) |
| G4 | `mergetool.prompt` を `false` にする (`difftool` と揃え、ファイルごとの確認を出さない) |
| C1・C2 | ステータスラインを、jq を 1 回だけ起動し、ディレクトリ名を jq の中で取る形にする。コンテキストの使用率は出さない (usage-hint に任せる)。出すのは モデル名・ディレクトリ名・費用 |
| O4 | VSCode の `<Leader> q` の 2 つ目の割り当て (`editor.action.quickFix`。効いていない) を消す |
| Z12 | `setopt nolistbeep` と `alias where="command -v"` を消す |
| `Ctrl-R` | `FZF_CTRL_R_OPTS` で、選んでいるコマンドの全体を下に bat で色付きで出す (番号を除き、複数行のコマンドは元の行に戻す。`cut -f2-`)。プレビューは折り返し、`Ctrl-O` で表示を切り替える |
| bat-extras | `batgrep`・`batdiff` を Nix で入れる (`pkgs.bat-extras.batgrep`・`pkgs.bat-extras.batdiff`)。`dependencies.md` と sync-deps の名前の対応表にも書く |
| eza | `e` に `--hyperlink` を、`et` に `--git-ignore` を足す。`tmux/tmux.conf` に `set -as terminal-features ",*:hyperlinks"` を足す |

- `docs/specifications.md` と README の、関係する記述を直す。
- bat-extras は Nix の変更なので、本人が `sudo darwin-rebuild switch --flake ~/dotfiles#dione` を実行する。

## 実装しないこと

- fzf の `Alt-C` (使っていない)。
- bat-extras の `batman` (`MANPAGER` で bat を使っている。[ADR 0053](0053-bat-manpager-and-eza-options.md))・`batpipe`・`batwatch`・`prettybat`。
- O4 の `editor.action.quickFix` を別のキーに割り当てること (今も効いていないので、使い勝手は変わらない)。
- I10 (adr-guard のリポジトリで本人が扱う)。
- 改善案のほかの残り (Z8・V5・V12・G2・O2 と、tmux・zsh・nvim の便利な設定)。

## テスト設計

- `zsh/tests/` に、`Ctrl-R` のプレビューのコマンドのテストを足す。fzf の候補の形 (番号 + タブ + コマンド、続きの行はタブ + 続き) を入力にし、
  番号が外れ、複数行のコマンドが元の行に戻ることを確かめる (`FZF_CTRL_R_OPTS` からプレビューのコマンドを取り出して実行する)。
- ステータスラインは、自動テストを書かない。jq の入力の例 (空白と引用符を含むディレクトリ名、費用あり・なし、モデル名なし) を与えて、
  `モデル名 ディレクトリ名 [費用]` が出ること、コンテキストの使用率が出ないことを確かめる。
- 設定の値の変更は、自動テストを書かない。次を確かめる。
  - `git config --get-regexp '^alias\.(lgraph|cl)$'` が何も出さず、`git config --get mergetool.prompt` が `false` であること。
  - `vscode/settings.json` が JSONC として読め、`<leader> q` の割り当てが 1 つであること。
  - 新しい zsh で `setopt` の一覧に `nobeep` があり (ビープは止まったまま)、`where` が組み込みのものであること (`whence -w where` が `builtin`)。
  - 新しい zsh で `e`・`et` のエイリアスにオプションが入っていること。別の tmux サーバーで `terminal-features` に `hyperlinks` があること。
  - `darwin-rebuild` の後に、`batgrep`・`batdiff` が動くこと (本人が実行した後に確かめる)。
- 既存の zsh のテストがすべて通ること。
- `Ctrl-R` のプレビューと eza のリンクの見え方は本人が確かめる。

## トレードオフ

- G3: `git lgraph`・`git cl` が使えなくなる (`git lg`・`git cia` を使う)。
- G4: `git mergetool` が、ファイルごとに確認せずに次々と nvimdiff を開く。
- C2: ステータスラインにコンテキストの使用率が出なくなる (usage-hint が出す。usage-hint が動いていないときは見えない)。
- Z12: `where` の出力が `command -v` (1 つ) から、組み込みの `where` (すべての候補) に変わる。
- `Ctrl-R`: プレビューの分だけ、一覧に使える行が減る。
- eza: `et` で `.gitignore` に書いたもの (`node_modules` など) が見えなくなる。見たいときは `e --tree` を使う。
  `--hyperlink` は、リンクに対応しない端末ではそのまま無視される。
