# ADR 0036: tmux のウィンドウの切り替えを Ctrl-T に移す

ステータス: 採択

## 文脈

ADR 0033 で、fzf で tmux のウィンドウを選んで切り替えるウィジェット (`ftmux_window`) を `Ctrl-E` に割り当てた。
これを `Ctrl-T` に移したい。

- `Ctrl-T` には、fzf 本体 (`fzf --zsh`) がファイルを選んで入力行に足すウィジェット (`fzf-file-widget`) を割り当てている。
- 同じ `fzf-file-widget` は `Ctrl-P` にも割り当ててあり (`zsh/fzf.sh`)、ファイルの選択は `Ctrl-P` で行っている。
  `Ctrl-T` の割り当ては使っていない。
- `zsh/fzf.sh` は `zshrc` で `fzf --zsh` の後に読み込むので、ここでの `bindkey` が fzf 本体の割り当てを上書きする。

## 実装すること

- `zsh/fzf.sh` の `bindkey "^e" ftmux_window` を `bindkey "^t" ftmux_window` にする。
  - `Ctrl-T` の `fzf-file-widget` の割り当ては、上書きされて無くなる。ファイルの選択は `Ctrl-P` を使う。
  - `Ctrl-E` は割り当てが無くなり、zsh の vi 挿入モードの既定 (`self-insert`) に戻る。
- ファイルの選択のプレビュー (`FZF_CTRL_T_OPTS`。ADR 0034) は、`Ctrl-P` の `fzf-file-widget` が引き続き使う。
  変数の名前は fzf 本体が決めているので変えない。
- コマンド選択 (`Ctrl-O`) の一覧の `ftmux_window` のキーの表示は、`bindkey` から引いているので自動で `^T` になる。
- `zsh/tests/fzf-command-finder.test.zsh` の、`ftmux_window` のキーを確かめるテストの期待値を `^T` にする。
- `docs/specifications.md` のキーの表の `Ctrl-E` を `Ctrl-T` にし、fzf のプレビューの説明から `Ctrl-T` を外す。
- ADR 0033 のステータスを「採択→キーの割り当て (Ctrl-E) はADR 0036」、ADR 0034 のステータスを
  「採択→Ctrl-T のプレビューはADR 0036 (Ctrl-P だけになる)」にする。

## 実装しないこと

- `Ctrl-E` への別の機能の割り当て。
- `FZF_CTRL_T_OPTS` 以外の fzf 本体の設定の変更。

## テスト設計

- 先にテストの期待値を `^T` に変えて失敗させてから、`bindkey` を変える。
- `zsh/tests/` のテストがすべて通ること。
- 新しい zsh で、`bindkey -M viins '^T'` が `ftmux_window`、`bindkey -M viins '^E'` が `self-insert`、
  `bindkey -M viins '^P'` が `fzf-file-widget` であることを確かめる。
- 実際に `Ctrl-T` でウィンドウの一覧が出ることは本人が確かめる。

## トレードオフ

- fzf 本体の既定の `Ctrl-T` (ファイルの選択) が使えなくなる。fzf の説明や記事の `Ctrl-T` は、この環境では `Ctrl-P` に読み替える。
