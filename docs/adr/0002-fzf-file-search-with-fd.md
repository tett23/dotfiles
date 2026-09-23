# ADR 0002: fzf のファイル検索を fd に切り替え、fzf 同梱のキーバインドを使う

- Status: Accepted
- Date: 2026-09-23

## Context

`^P` (`fzf-file-widget`) のインクリメンタルファイル検索が失敗する。原因は 2 つ。

1. `zsh/fzf.sh` が `FZF_CTRL_T_COMMAND=find` を export している。
   macOS の BSD `find` はパス引数なしでは usage を出して exit 1 するため、
   fzf に渡る候補が空になる (GNU find 前提の設定だった)。
2. `fzf-file-widget` の定義元が `~/.fzf.zsh` → `~/.fzf/shell/key-bindings.zsh`
   (2018 年に手動 clone した x86_64 版で、`~/.fzf/bin/fzf` は Apple Silicon で
   起動不可)。dotfiles 管理外なので新規マシンでは存在せず、`^P` は未定義になる。
   一方、Nix (home-manager) で入れている fzf 0.73 は `fzf --zsh` で
   キーバインドを出力できる。

## Decision

- ファイル検索コマンドを `fd` にする (`dependencies.md` に既にある)。
  `FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'`、
  `FZF_CTRL_T_COMMAND` も同じ値にする。
- `~/.fzf.zsh` の読み込みをやめ、`source <(fzf --zsh)` で Nix の fzf 同梱の
  キーバインド・補完を読み込む。`fzf` が無い環境ではスキップする。
- `^P` → `fzf-file-widget` の bind は維持する。

## Consequences

- `^P` / `^T` が fd ベースの検索になり、`.git` 配下は除外、隠しファイルは含む。
- `~/.fzf` ディレクトリは不要になる (削除は各自の判断。残っていても害はない)。
- 独自ウィジェット (`repo`, `fbr` 等) が使う `__fzfcmd` は `fzf --zsh` 側でも
  同名で定義されるため互換。
