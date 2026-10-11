# ADR 0044: Ghostty に便利な設定を足す

ステータス: 提案

## 文脈

Ghostty (1.3.1。Nix の `ghostty-bin`) の設定 (`ghostty/config`) は、終了時の確認を止める設定と 2 つのキーの割り当てだけ。
Ghostty で使える設定のうち、次のものを入れる。

- zsh には `Alt-c` (fzf でディレクトリに移動)・`Alt-p` / `Alt-n` (履歴の検索) の割り当てがあるが、macOS の Ghostty は既定では
  Option キーを Alt として送らない (`macos-option-as-alt` が未設定) ため、Option を押すと特殊な文字が入り、どれも効いていない。
- Ghostty は Nix で入れていて、更新は `bin/update-nix` で行う。Ghostty 自身の自動更新 (`auto-update`) は未設定。
- nvim の配色は monokai-pro の classic (ADR 0009)。Ghostty には同系統の組み込みのテーマ `Monokai Classic` がある。

マウスのカーソルを入力中に隠す設定 (`mouse-hide-while-typing`) とフォントの指定は入れない (本人の判断)。

## 実装すること

`ghostty/config` に次を足す。

| 設定                     | 値                                              | 効果                                                                                |
| ------------------------ | ----------------------------------------------- | ----------------------------------------------------------------------------------- |
| `macos-option-as-alt`    | `left`                                          | 左の Option キーを Alt として送る。右の Option では従来どおり特殊な文字を入力できる |
| `auto-update`            | `off`                                           | Ghostty 自身の自動更新を止める (Nix で管理するため)                                 |
| `theme`                  | `Monokai Classic`                               | 端末の配色を nvim と揃える                                                          |
| `keybind`                | `global:cmd+backslash=toggle_quick_terminal` | どのアプリからでも `Cmd+\` で、画面の上から端末 (quick terminal) を出し入れする    |
| `window-save-state`      | `always`                                        | 終了したときのウィンドウ・タブの配置を、次の起動で戻す                              |
| `window-padding-balance` | `true`                                          | ウィンドウの余白を上下左右で均等にする                                              |

- `docs/specifications.md` に Ghostty の節を作り、これらと既存の設定 (`Cmd+P`・`Ctrl+J`) を書く。

## 実装しないこと

- `mouse-hide-while-typing`・フォント (`font-family`・`font-size`) の指定。
- `Cmd+P` が tmux の中の nvim に届かない可能性 (監査 2026-10-11 の O3) への対応。

## テスト設計

- 設定ファイルの変更のため、自動テストは書かない。
- `ghostty +validate-config --config-file=ghostty/config` で、設定にエラーが無いことを確かめる。
- 本人が確かめる (Ghostty の設定の読み込み直し `Cmd+Shift+,`、または再起動の後):
  - zsh で左の `Option+c` を押すと、fzf でディレクトリを選べること。
  - `Cmd+\` で、ほかのアプリの前に quick terminal が出ること (初回は macOS のアクセシビリティの許可を求められる)。
  - 配色が Monokai Classic になること。

## トレードオフ

- 左の Option キーでは、特殊な文字 (`å`・`∫` など) を入力できなくなる。右の Option を使う。
- `Cmd+\` は、どのアプリにいるときも Ghostty が受け取るので、ほかのアプリの `Cmd+\` (1Password の自動入力の既定など) が
  効かなくなる。今は 1Password は入っていない。
- quick terminal の全体のキーの割り当てには、macOS のアクセシビリティの許可が必要。
- tmux の中では、tmux の `window-style` などの色の指定が優先されるので、テーマの効果は主に ANSI の色 (16 色) に出る。
- Ghostty の更新は `bin/update-nix` だけになる (自動では上がらない)。
