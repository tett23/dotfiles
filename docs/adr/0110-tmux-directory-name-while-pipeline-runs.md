# ADR 0110: パイプラインの実行中も、tmux のウィンドウ名とタイトルにディレクトリ名を出す

ステータス: 採択

## 文脈

本人から、tmux で bat などのプロセスを動かしているときに、タブの名前がディレクトリ名でなくなるのを直せるかと聞かれた。

tmux のディレクトリ名は、次のところで `#{pane_current_path}` から作っている。

- ステータスラインのウィンドウ名 (`tmux/statuses.conf` の `@nova-pane` の `#{b:pane_current_path}`。[ADR 0007](0007-tmux-status-directory-name.md))
- Ghostty のタイトル (`tmux/tmux.conf` の `set-titles-string "#{b:pane_current_path}: #{pane_current_command}"`。[ADR 0088](0088-tmux-sets-ghostty-title.md))
- `Ctrl-T` のウィンドウの一覧 (`tmux/scripts/window-switcher` の `#{b:pane_current_path}`)
- 新しいウィンドウとペインを開くディレクトリ (`bind c`・`bind s`・`bind v` の `-c "#{pane_current_path}"`)、`prefix Y` でコピーするディレクトリ

調べたことは次のとおり。

- 別の tmux のサーバー (`tmux -L` と dotfiles の `tmux.conf`) のペインでコマンドを動かし、2 秒後にタイトル (`#{T:set-titles-string}`) とウィンドウ名のディレクトリ (`#{b:pane_current_path}`) を見た。

  | コマンド | タイトル | ウィンドウ名のディレクトリ |
  | --- | --- | --- |
  | `bat docs/specifications.md` | `dotfiles: .bat-wrapped` | `dotfiles` |
  | `less docs/specifications.md` | `dotfiles: less` | `dotfiles` |
  | `man ls` | `dotfiles: .man-wrapped` | `dotfiles` |
  | `batgrep tmux tmux/tmux.conf` | `dotfiles: bash` | `dotfiles` |
  | `sleep 30` | `dotfiles: sleep` | `dotfiles` |
  | `cat docs/specifications.md \| bat` | `: zsh` | (空) |

  ディレクトリ名が消えたのは、パイプラインのときだけだった。
- tmux のソース (ghq で取得、`a73616d`) の `osdep-darwin.c` の `osdep_get_cwd`: 端末の前面のプロセスグループの番号 (`tcgetpgrp`) を、そのままプロセスの番号として
  `proc_pidinfo` に渡し、そのプロセスの今のディレクトリを読む。zsh のパイプラインでは、プロセスグループの番号は先頭のコマンド (`cat`) の番号である。
  `cat` が書き終えて終わると、その番号のプロセスが無くなり、`pane_current_path` は空になる。`pane_current_command` も前面のプロセスを見つけられず、シェル (`zsh`) になる。
- tmux は、ペインの中のプログラムが送る OSC 7 (今のディレクトリ) を `#{pane_path}` に入れる (`input.c` の `input_osc_7`)。tmux はこれを外の端末に渡さない。
  別のサーバーで `printf '\e]7;file://%s%s\a' $HOST $PWD` を送ると、`#{pane_path}` は `file://dione4.local/Users/tett23/dotfiles` になり、
  その後の `cat docs/specifications.md | bat` の実行中も残った。
- dotfiles の `zsh/lib/tmux-osc7.zsh` ([ADR 0085](0085-open-relative-paths-in-ghostty-through-tmux.md)) は、tmux の中で、OSC 7 を passthrough で包んで Ghostty に送っている。
  passthrough の中身は tmux が読まないので、今の `#{pane_path}` は空である (今の tmux のサーバーのペインで確かめた)。
- tmux の書式で試したこと (別のサーバー):
  - `#{?pane_current_path,#{b:pane_current_path},#{b:pane_path}}` を `@cwd-name` に入れ、`#{E:@cwd-name}` で読むと、パイプラインの実行中も `dotfiles` になった。`list-windows -F` でも同じ。
  - `#{?pane_current_path,#{pane_current_path},#{s|^[^/]*//[^/]*||:pane_path}}` を `@cwd` に入れ、`#{E:@cwd}` で読むと、パイプラインの実行中も `/Users/tett23/dotfiles` になった。
  - `s` の置き換えの式に `:` を書くと、そこで修飾子が終わり、空になった (`file:` で始まる式は使えない)。`#{b:#{E:@cwd}}` は basename にならなかった。

## 実装すること

- `zsh/lib/tmux-osc7.zsh`: tmux の中では、passthrough で包んだ OSC 7 に加えて、包まない OSC 7 (`\e]7;file://<ホスト><パス>\a`) も送る。tmux はこれを `#{pane_path}` に入れる。
  包まない OSC 7 を作る関数を足し、注釈にこの ADR を書く。
- `tmux/tmux.conf`:
  - `@cwd` に `#{?pane_current_path,#{pane_current_path},#{s|^[^/]*//[^/]*||:pane_path}}` を、`@cwd-name` に `#{?pane_current_path,#{b:pane_current_path},#{b:pane_path}}` を入れる。
    注釈に、パイプラインの実行中は `pane_current_path` が空になるので、シェルが OSC 7 で知らせたディレクトリを使うことと、この ADR を書く。
  - `set-titles-string` を `#{E:@cwd-name}: #{pane_current_command}` にする。
  - `bind c`・`bind s`・`bind v` の `-c` と `prefix Y` を `#{E:@cwd}` にする。
- `tmux/statuses.conf` の `@nova-pane` の `#{b:pane_current_path}` を `#{E:@cwd-name}` にする。
- `tmux/scripts/window-switcher` の `#{b:pane_current_path}` を `#{E:@cwd-name}` にする。
- `docs/specifications.md` の tmux の節に書く。README は変えない。

## 実装しないこと

- パイプラインの実行中のコマンド名 (`pane_current_command` が `zsh` になること) を直すこと。tmux は前面のプロセスを見つけられないので、dotfiles の設定では直せない。
- tmux に、プロセスグループの番号でなく、グループの中の生きているプロセスを探すよう直すこと (tmux への提案)。

## テスト設計

- `zsh/tests/tmux-osc7.test.zsh` に、包まない OSC 7 の関数のテスト (passthrough の関数と同じく、空白と日本語、制御文字) と、`_tmux_osc7_report` が tmux の中で両方を書くテストを足し、先に失敗させる。
- 設定の変更は、実装の前と後に次を行って確かめる。別の tmux のサーバー (`tmux -L <名前> -f ~/.config/tmux/tmux.conf`) を起動し、確かめた後に止めて、`~/.local/run/tmux-501/` のソケットを消す。
  - 上の表のコマンドを動かし、タイトル (`#{T:set-titles-string}`)・ウィンドウ名 (`#{T:window-status-current-format}`)・`window-switcher` と同じ `list-windows -F` の結果を見る。
    実装の後は、`cat docs/specifications.md | bat` の実行中もディレクトリ名 `dotfiles` が出る (コマンド名は `zsh`)。ほかのコマンドは変わらない。
  - パイプラインの実行中に `#{E:@cwd}` が `/Users/tett23/dotfiles` になる。
- 本人が確かめる: Ghostty の tmux で `cat <ファイル> | bat` を動かすと、ステータスラインのウィンドウ名と Ghostty のタブの名前がディレクトリ名のままである。
  新しい tmux のペインのシェルで確かめる (今のシェルは新しい `tmux-osc7.zsh` を読んでいない)。

## 結果

- `zsh/tests/tmux-osc7.test.zsh` に足したテストは、実装の前は 3 つ失敗し (`tmux_osc7_plain_sequence` が無い)、実装の後はすべて通った。
- 別の tmux のサーバー (ペインで `zsh -i` を動かす) で、「文脈」の表のコマンドを動かした。

  | コマンド | 実装の前 (タイトル / ウィンドウ名 / 一覧 / `#{E:@cwd}`) | 実装の後 |
  | --- | --- | --- |
  | `bat`・`less`・`man`・`batgrep`・`sleep` | `dotfiles: <コマンド>` / `dotfiles` / `dotfiles  <コマンド>` / 空 (`@cwd` が無い) | 同じ。`#{E:@cwd}` は `/Users/tett23/dotfiles` |
  | `cat docs/specifications.md \| bat` | `: zsh` / 空 / `  zsh` / 空 | `dotfiles: zsh` / `dotfiles` / `dotfiles  zsh` / `/Users/tett23/dotfiles` |

- 実装の後のペインの `#{pane_path}` は `file://dione4.local/Users/tett23/dotfiles` だった。
- パイプラインの実行中に `new-window -c '#{E:@cwd}'` と `split-window -c '#{E:@cwd}'` で開いたペインは、どちらも `/Users/tett23/dotfiles` で始まった。
- `prefix Y`: `#{q:#{E:@cwd}}` も `#{q;E:@cwd}` も、`@cwd` の中身を引用しなかった (前者は引用せず、後者は書式そのものを引用した)。
  そこで「実装すること」の `#{E:@cwd}` を、コマンドに埋めずに `run-shell -c "#{E:@cwd}"` で渡し、そのディレクトリで `pwd` を読む形にした。
  別のサーバーで `run-shell -c '#{E:@cwd}'` の `pwd` をファイルに書くと、パイプラインの実行中も `/Users/tett23/dotfiles` だった (クリップボードは変えないよう、`pbcopy` は動かしていない)。
- 確かめた後、別のサーバーを止め、`~/.local/run/tmux-501/cctitle` を消した。

## トレードオフ

- パイプラインの実行中は、シェルが最後に知らせたディレクトリ (プロンプトを出したときか `cd` したとき) を出す。パイプラインの中で `cd` したコマンドのディレクトリは出ない。
- プロンプトのたびに送る OSC 7 が 2 つになる。
- ペインの中のほかのプログラム (ssh の先のシェルなど) が OSC 7 を送ると、`#{pane_path}` はそのディレクトリになる。パイプラインの実行中にだけ使うので、ふだんの表示は変わらない。

## 参考文献

- tmux のリポジトリ (ghq で取得、`a73616d`): `osdep-darwin.c` (`osdep_get_cwd`)、`input.c` (`input_osc_7`)、`screen.c` (`screen_set_path`)
- tmux 3.8 の `man tmux` (`pane_path`、書式の修飾子 `b:`・`E:`・`s/`)
- 別の tmux のサーバーで動かした結果
