# ADR 0007: tmux のステータスラインにプロセス名ではなくディレクトリ名を表示する

- Status: Accepted
- Date: 2026-10-06

## Context

tmux-nova のウィンドウ表示 (`@nova-pane`) は
`#I:#P ... #(basename $(short-pwd)) #W` で、ディレクトリ名とウィンドウ名を出す意図だった。
実際にはディレクトリ名が出ず、プロセス名 (`zsh` 等) だけが表示されている。

- `#(...)` はペインではなく tmux サーバーのプロセスとして実行されるため、
  ペインの現在ディレクトリを返さない。
- さらに `short-pwd` は tmux サーバーの PATH に無く、shebang も `#/bin/env` と
  壊れているため、評価結果は空文字になる。
- `#W` は `automatic-rename` により `pane_current_command` (プロセス名) になる。

tmux 3.6a は書式 `#{b:pane_current_path}` でアクティブペインの現在ディレクトリの
ベース名を直接返せる。外部コマンドが不要で、`status-interval` ごとに更新される。

## Decision

- `@nova-pane` の `#(basename $(short-pwd)) #W` を `#{b:pane_current_path}` に置き換える。
  プロセス名 (`#W`) は表示しない。
- ペイン枠 (`pane-border-format`) の `pane_current_command` は今回は変えない。

## Consequences

- ステータスラインの各ウィンドウに、アクティブペインのディレクトリ名が出る。
- 外部コマンドの実行が無くなり、`short-pwd` に依存しなくなる。
- 手動で付けたウィンドウ名 (`rename-window`) はステータスラインに出なくなる。
