# ADR 0070: fzf で git の worktree を選んで移動する

ステータス: 採択

## 文脈

本人から、git の worktree へ fzf で選んで移動するコマンドが欲しい、キーは空いているものから提案してほしいと要望があった。
プロンプトには worktree の名前が出るようになった ([ADR 0069](0069-git-prompt-worktree-name.md))。

- `zsh/fzf.sh` の fzf のコマンドは、`__<名前>` の関数 (コマンド選択 `Ctrl-O` に出る。直前の 1 行のコメントが説明) と、同じ名前の
  ウィジェット (キーに割り当てる) の組で作る ([ADR 0033](0033-fzf-tmux-window-switcher.md))。`Ctrl-O` は `__<名前>` の出力を入力行に足す。
  `$(…)` の中で呼ぶので、`__<名前>` の中で `cd` しても、今のシェルには効かない。
- fzf の入出力を解析する処理は、純粋な関数にして `zsh/tests/fzf-parse.test.zsh` でテストする ([ADR 0046](0046-fix-audit-non-breaking.md))。
- `git worktree list --porcelain` は、worktree ごとに `worktree <パス>`・`HEAD <ハッシュ>`・`branch refs/heads/<名前>` (detached なら `detached`、
  bare なら `bare`) の行を出し、空行で区切る。
- zsh の vi の挿入モード (`viins`) で、Ctrl とアルファベットのキーの今の割り当てを調べた。

  | キー | 今 | 使えるか |
  |---|---|---|
  | `Ctrl-E` | 無し | 使える。tmux・Ghostty も使っていない (以前は tmux のウィンドウの切り替えに使い、[ADR 0036](0036-tmux-window-switcher-on-ctrl-t.md) で `Ctrl-T` に移した) |
  | `Ctrl-Y` | 無し | 使える |
  | `Ctrl-N` | 無し | 使える (fzf の中では下へ移動のキーだが、入力行では空いている) |
  | `Ctrl-A` | 無し | 使えるが、ほかの環境で行頭へ移動のキーとして手が覚えていることが多い |
  | `Ctrl-S`・`Ctrl-Z`・`Ctrl-C`・`Ctrl-Q` | 端末の停止・中断や、tmux の prefix | 使えない |
  | `Ctrl-W` (worktree の頭文字) | 単語を消す | 使えない |

## 実装すること

- `zsh/fzf.sh` に、worktree を選んで移動するコマンドを足す。
  - 純粋な関数 `fzf_worktree_lines`: `git worktree list --porcelain` の出力と今の worktree のパスを受け取り、worktree ごとに
    `<印> <名前> <ブランチ> <パス>` の 1 行をタブ区切りで出す。印は今の worktree が `*`、それ以外は空白。名前はパスの最後の部分。ブランチは `refs/heads/` を外した名前、
    detached なら `(detached <ハッシュの先頭 7 文字>)`。bare の worktree は出さない (移動しても作業できないため)。
  - `__fworktree` (説明「git の worktree を選び、移動する cd のコマンドを入力行に足す」): 今のディレクトリが git のリポジトリの中なら、一覧を fzf で選ばせ、
    `cd -- <パス>` を出す。fzf の絞り込みは名前とブランチの列だけを対象にする (パスの文字に一致させない)。プレビューにはその worktree の
    `git status --short --branch` を下に出す。リポジトリの外では何もしない。
    `Ctrl-O` から選ぶと、入力行に `cd -- <パス>` が入る (Enter で移動する)。
  - ウィジェット `fworktree`: `__fworktree` の結果で、その場で移動する (入力行は変えない)。移動の後、プロンプトの git の表示を作り直して描き直す
    (`precmd` の関数を呼んでから `zle reset-prompt`)。
- キーは `Ctrl-E` に割り当てる (`bindkey "^e" fworktree`)。
- `docs/specifications.md` の fzf のキーの表に書く。

## 実装しないこと

- worktree の作成・削除 (`git worktree add`・`remove`)。
- ghq の別のリポジトリの worktree も含めて一覧にすること (今いるリポジトリの worktree だけ)。
- tmux の新しいウィンドウで開くこと。

## テスト設計

先にテストを書いて失敗させてから実装する。

- `zsh/tests/fzf-parse.test.zsh` に `fzf_worktree_lines` のテストを足す。
  - ブランチ・detached・bare を含む `--porcelain` の出力から、bare を除いた行が出ること。今の worktree に `*` が付くこと。
  - パスに空白を含む worktree も 1 行になること。
  - 入力が空なら何も出さないこと。
- `zsh/tests/fzf-command-finder.test.zsh` に、`fworktree` がコマンド選択の一覧に出て、キーが `^E` であることを足す。
- `fzf_worktree_path` が、選んだ行からパス (空白を含む) を取り出すことを確かめる。
- 自動テストにしにくい部分は、実装の後に別の tmux サーバーで確かめる。worktree を持つリポジトリで `Ctrl-E` を押して選ぶと、
  そのディレクトリに移動し、プロンプトの git の表示が `[ブランチ / 名前]` に変わること。リポジトリの外では何も起きないこと。

## トレードオフ

- `Ctrl-E` には意味の上の結び付き (worktree の頭文字など) が無い。頭文字の `Ctrl-W` は単語を消すキーで使えない。
- キーで呼ぶとその場で移動し、`Ctrl-O` から呼ぶと入力行に `cd` が入る、と呼び方で動きが違う (`Ctrl-O` は出力を入力行に足す仕組みのため)。
- キーで移動したときは、`cd` が履歴に残らない。

## 参考文献

- git-worktree(1) の `list --porcelain`: https://git-scm.com/docs/git-worktree#_porcelain_format
- zsh の ZLE (ウィジェット・`reset-prompt`): https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html
