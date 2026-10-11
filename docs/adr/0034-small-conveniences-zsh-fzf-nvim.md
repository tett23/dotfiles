# ADR 0034: zsh・fzf・nvim に、広く使われている小さな便利設定を足す

ステータス: 採択→Ctrl-T のプレビューはADR 0036 (Ctrl-P だけになる)

## 文脈

zsh・fzf・nvim の設定を見直したところ、広く使われていて、数行で入れられる便利な設定のうち、次の 6 つが入っていなかった。

- zsh: 入力中のコマンドをエディタで編集する (`edit-command-line`)。補完で大文字と小文字を区別しない。
- fzf: `Ctrl-T` (と同じウィジェットを割り当てた `Ctrl-P`) でファイルの中身をプレビューする。
- nvim: nvim を閉じた後も undo できる (`undofile`)。ヤンクした範囲を一瞬光らせる。ファイルを前回のカーソル位置から開く。

調べて分かった事情は次のとおり。

- zsh は vi モード (`bindkey -v`) で、ノーマルモード (`vicmd`) の `v` は入力行の範囲選択 (`visual-mode`) に使われている。
  ただし入力行のコピーは tmux のコピーモードで行うため、`visual-mode` は使っていない。`v` で `$EDITOR` を開くのは、
  vi モードの定番の割り当て (vi・bash の vi モードと同じ)。
- `Ctrl-X Ctrl-E` は挿入モード・ノーマルモードとも割り当てが無い (bash・emacs のキー割り当てで `edit-command-line` に使う定番のキー)。
- `zsh/fzf.sh` の独自のコマンド (`repo`・`fbr`・git や docker のコマンド・コマンド選択など 10 か所) は、fzf に
  `$FZF_CTRL_T_OPTS` を渡している。今はこの変数が空なので影響が無いが、`Ctrl-T` のプレビューをこの変数に書くと、
  ファイルではない一覧 (リポジトリ・ブランチ・コマンド名など) にも `bat` のプレビューが付いて、エラーが表示される。
- nvim は `swapfile` と `backup` を無効にしている。nvim のバージョンは 0.12。

## 実装すること

### zsh

- `zsh/common.sh` の `bindkey -v` の近くで、`edit-command-line` を読み込み、ノーマルモードの `v` と、
  挿入モード・ノーマルモードの `Ctrl-X Ctrl-E` に割り当てる。ノーマルモードの `v` の範囲選択 (`visual-mode`) は無くなる。

  ```zsh
  autoload -Uz edit-command-line
  zle -N edit-command-line
  bindkey -M vicmd 'v' edit-command-line
  bindkey -M viins '^X^E' edit-command-line
  bindkey -M vicmd '^X^E' edit-command-line
  ```

  - 編集には `$EDITOR` (nvim) を使い、保存して閉じると入力行に戻る。
- 補完で、小文字の入力が大文字にも一致するようにする (大文字の入力は大文字にだけ一致する)。

  ```zsh
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
  ```

  - `zsh/completions.sh` の `compinit` の前に書く。

### fzf

- `zsh/fzf.sh` の独自のコマンドから `$FZF_CTRL_T_OPTS` を外す (今は空なので、外しても挙動は変わらない)。
- `FZF_CTRL_T_OPTS` に、`bat` でファイルの先頭をプレビューする設定を書く。

  ```zsh
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
  ```

  - `Ctrl-T` と `Ctrl-P` (どちらも `fzf-file-widget`) で、選ぶ前にファイルの中身が見える。
  - 一覧は `FZF_CTRL_T_COMMAND` (`fd --type f`) でファイルだけなので、ディレクトリのプレビューは考えない。

### nvim

- `nvim/lua/config/options.lua` に `opt.undofile = true` を足す。undo の履歴は nvim の既定の場所
  (`~/.local/state/nvim/undo/`) に保存される。
- `nvim/lua/config/autocmds.lua` に次の 2 つを足す。
  - ヤンクした範囲を一瞬光らせる: `TextYankPost` で `vim.hl.on_yank()` を呼ぶ。
  - 前回のカーソル位置から開く: 前回閉じたときの位置 (`'"` マーク) がファイルの行数の範囲内なら、そこへ移る。
    git のコミットメッセージなど (`gitcommit`・`gitrebase`) は、毎回先頭から書くので対象外にする。
    読み込んだ時点 (`BufReadPost`) ではファイルの種類がまだ決まっていないため、`BufReadPost` でそのバッファの
    `BufWinEnter` を一度だけ登録し、そこで判定して移る (nvim のヘルプ `:h last-position-jump` の例と同じ)。

### ドキュメント

- `docs/specifications.md` の zsh のキーの表に、ノーマルモードの `v` と `Ctrl-X Ctrl-E` を足し、補完・fzf のプレビュー・nvim の 3 つの設定を書く。

## 実装しないこと

- `vv` への割り当て (`v` を押した後に次のキーを待つ遅れが出るため)。
- そのほかの候補 (補完候補のカーソルでの選択・補完候補の色・`magic-space`・zoxide・`Alt-C` の設定・`Ctrl-R` のプレビュー・
  nvim の `inccommand`・`scrolloff`・ウィンドウの分割の向き・`signcolumn`)。必要になったら別の ADR にする。
- 独自のコマンドへのプレビューの追加。

## テスト設計

- 設定ファイルの変更のため、自動テストは書かない。
- 新しい zsh で次を確かめる。
  - `bindkey -M vicmd 'v'`・`bindkey -M viins '^X^E'`・`bindkey -M vicmd '^X^E'` が `edit-command-line` であること。
  - `zstyle -L ':completion:*'` に `matcher-list` の設定があること。
  - `FZF_CTRL_T_OPTS` にプレビューの設定があり、`zsh/fzf.sh` に `FZF_CTRL_T_OPTS` の参照が残っていないこと。
- 既存の zsh のテスト (`zsh/tests/`) がすべて通ること。
- nvim をヘッドレスで起動し、次を確かめる。
  - `vim.o.undofile` が `true` であること。
  - `TextYankPost` と `BufReadPost` の autocmd が登録されていること。
- 別の tmux サーバーの中で nvim を起動してキーを送り、次を確かめる (ヘッドレスの nvim はカーソルや ShaDa の扱いが
  通常と違うため)。試験のファイルはホームの下に置く (`/tmp/`・`/private/` の下のファイルは、nvim の既定の `shada` の
  `r` の指定で前回の位置が記録されない)。
  - ファイルの 5 行目で閉じて開き直すと、カーソルが 5 行目にあること。
  - `COMMIT_EDITMSG` の最終行で閉じて開き直すと、カーソルが 1 行目にあること。
- 実際の使い心地 (ノーマルモードの `v` と `Ctrl-X Ctrl-E` で nvim が開いて戻ること、大文字小文字を区別しない補完、`Ctrl-T`・`Ctrl-P` のプレビュー、
  ヤンクのハイライト、undo の保存) は本人が確かめる。

## トレードオフ

- zsh のノーマルモードの `v` による入力行の範囲選択が使えなくなる (コピーは tmux のコピーモードで行う)。
- 小文字の入力で大文字のファイルも補完候補に出るため、候補が増えることがある。
- `Ctrl-T`・`Ctrl-P` で、カーソルを動かすたびに `bat` が起動する (先頭 200 行に絞る)。
- undo の履歴のファイルが `~/.local/state/nvim/undo/` に増えていく (自動では消えない)。
- `$FZF_CTRL_T_OPTS` を独自のコマンドから外すため、今後この変数に足した設定は独自のコマンドには効かない。
