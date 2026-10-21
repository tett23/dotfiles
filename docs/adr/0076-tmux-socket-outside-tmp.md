# ADR 0076: tmux のソケットを /tmp の外に置き、別のサーバーにつながったら知らせる

ステータス: 採択

## 文脈

本人から、tmux のセッションが複数あるとき、fzf の切り替えで別のセッションの一覧 (`tmux ls` のようなもの) が出るようだと報告があった。

調べた結果は次のとおり。

- 手元で動いている tmux のサーバーが 2 つあり、どちらも同じソケット `/private/tmp/tmux-501/default` を開いていた (`lsof`)。
  - 58301: 10-13 に起動した、ふだん使っているサーバー (`tmux a` のクライアントがつながり、ペインのシェルが 5 つ)。
  - 41749: 10-21 20:02 に、VSCode の端末の設定 (`vscode/settings.json` の `tmux new-session -A -s "$(basename …)#$"`) が起動したサーバー
    (セッション `golem#$`)。
- `/private/tmp/tmux-501/` は 10-21 20:02 に作り直されていた。古いサーバーのソケットのファイルが、何らかの理由で消え、
  VSCode の `tmux new-session -A` がソケットを見つけられずに、同じ場所で新しいサーバーを起動したとみられる。
  同じく `/private/tmp` の下に置いていた、作業用の tmux のサーバー (10-11 に起動) のソケットも消えていた。
  何が消したかは分からなかった (macOS 27 には、従来の `periodic` の `clean-tmps` が無い)。
- tmux のコマンドは、環境変数 `TMUX` (`<ソケットのパス>,<サーバーの pid>,<セッション>`) のパスでサーバーにつなぐ。古いサーバーのペインの
  シェルや、そのサーバーのポップアップ (`Ctrl-T` のウィンドウの切り替え。`tmux/scripts/window-switcher`) から `tmux list-windows -a` などを
  実行すると、同じパスにいる新しいサーバーにつながり、そちらのセッション (`golem#$`) の一覧が出る。報告の「別のセッションの一覧」はこれ。
- 手元の zsh の `Ctrl-E` (worktree の切り替え。[ADR 0070](0070-fzf-worktree-switcher.md)) は tmux を呼ばない。tmux のセッションを 2 つ作った
  別の tmux サーバーで試しても、tmux の一覧は出なかった。報告の操作は `Ctrl-T` (ウィンドウの切り替え) か、`tmux` を呼ぶほかの操作とみられる。
- tmux は、ソケットの場所を環境変数 `TMUX_TMPDIR` (無ければ `/tmp`) の下の `tmux-<uid>/` に置く。dotfiles は `XDG_RUNTIME_DIR` を
  `~/.local/run` にしている (`zsh/zshenv`。[ADR 0055](0055-improvements-2026-10-13.md))。
- tmux のサーバーは、`SIGUSR1` を受けるとソケットを作り直す。

## 実装すること

- `zsh/zshenv` で `TMUX_TMPDIR` を `$XDG_RUNTIME_DIR` (`~/.local/run`) にし、ディレクトリが無ければ作る (`700`)。tmux のソケットは
  `~/.local/run/tmux-<uid>/default` になり、`/tmp` の掃除で消えなくなる。zshenv はすべての zsh (VSCode の端末の `zsh -c` を含む) が読む。
- `tmux/scripts/window-switcher` で、`TMUX` の pid と、つながったサーバーの pid (`tmux display-message -p '#{pid}'`) を比べ、違うときは
  一覧を出さずに「tmux のソケットが別のサーバーに置き換わっている」ことと直し方を出して終わる。
- `docs/specifications.md` の tmux の節に書く。
- 今の 2 つのサーバーの片付けは、本人が行う (下の「移行」)。

## 移行

- この変更の後に起動した tmux は、新しい場所のソケットを使う。今動いているサーバーは `/tmp` のソケットのままなので、新しいシェルから
  `tmux a` してもつながらない。
- 本人が、両方のサーバーのペインの作業を終えてから、両方のサーバーを止めて (`kill <pid>`)、新しいシェルで tmux を起動し直す。
  古いサーバーを使い続けたいときは、新しいサーバー (41749) を止めた後に `kill -USR1 58301` で古いサーバーのソケットを作り直す。

## 実装しないこと

- VSCode の端末のセッション名 (`#$` が付く) の見直し (別に扱う)。
- `/tmp` のファイルを消している原因の特定。
- `window-switcher` 以外の tmux を呼ぶ処理 (`prefix + y` など) に、同じ確認を足すこと。

## テスト設計

先にテストを書いて失敗させてから実装する。

- `zsh/tests/window-switcher.test.zsh` を足す。作業用のソケットで tmux のサーバーを 2 つ起動し、`TMUX` を「1 つ目のソケットのパスと、
  2 つ目のサーバーの pid」にして `window-switcher` を実行すると、fzf (偽物を PATH に置き、呼ばれたら記録する) を呼ばずに 0 以外で終わり、
  置き換わっていることを出すこと。`TMUX` が正しいときは、今どおり fzf を呼ぶこと。
- `zsh -c 'print $TMUX_TMPDIR'` が `~/.local/run` で、そのディレクトリがあり、権限が `700` であること。その環境で起動した tmux の
  ソケットが `~/.local/run/tmux-<uid>/default` にできること (作業用のサーバーで確かめる)。
- 既存の zsh のテストと、CI の shellcheck が通ること。

## トレードオフ

- 移行のときに、今のサーバーにつなぎ直す手間がかかる。
- `~/.local/run` が消えると、同じ問題が起きる (`/tmp` より消えにくい)。
- `TMUX_TMPDIR` を設定しない環境 (zsh を通さずに起動した tmux) は、`/tmp` を使うので、別のサーバーになる。

## 参考文献

- tmux(1) の `TMUX_TMPDIR`・`-L`・`-S`・`SIGUSR1`: https://man.openbsd.org/tmux.1
- XDG Base Directory の `XDG_RUNTIME_DIR`: https://specifications.freedesktop.org/basedir-spec/latest/
