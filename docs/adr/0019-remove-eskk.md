# ADR 0019: eskk.vim と関連する設定・ファイルを削除する

- Status: Accepted
- Date: 2026-10-08

## Context

eskk.vim (nvim の SKK 日本語入力) はもう使っていない。一方で、関連する設定とファイルが残っていた。

- nvim のプラグイン指定 (`nvim/lua/plugins/editor.lua`) と `lazy-lock.json` の行
- home-manager の `~/.config/eskk` のリンク (dotfiles の `eskk/` を指す)
- `eskk/` ディレクトリ。中身は 2018 年にダウンロードした辞書 (`SKK-JISYO.L`、git の無視対象) と空の `log/` だけで、
  git の追跡対象のファイルが無い。そのため GitHub から clone したマシンではディレクトリごと存在せず、
  `~/.config/eskk` のリンクが切れる (VM での `curl | sh` の検証で判明)。
- `.gitignore` の `eskk/SKK-JISYO.L`
- ホームの `~/.eskk` (eskk.vim の実行ログ) と、旧 setup/install.sh が張った `~/.config/eskk` のリンク

日本語入力は AquaSKK (OS の入力メソッド) を使い続けるので、`skk/keymap.conf` などは対象外。

## Decision

- 上記の設定・行・ファイルをすべて削除する。
- ファイルの実体 (`eskk/` の辞書、`~/.eskk` のログ) は完全には消さず、ゴミ箱に移す。

## Consequences

- nvim で SKK による日本語入力はできなくなる (AquaSKK は使える)。
- 新規マシンで `~/.config/eskk` のリンク切れが起きなくなる。
