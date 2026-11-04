# ADR 0085: tmux の中でも Ghostty で相対パスを開けるようにし、rg・fd にリンクを出させる

ステータス: 採択

## 文脈

本人から、Ghostty で相対パスのリンクを開く方法を尋ねられた。Ghostty 1.4.0 のソース (ghq で取得した `v1.4.0`) を読んだ結果は次のとおり。

- 端末の文字から、URL とファイルのパスを見つけてリンクにする (`src/config/url.zig`)。`/`・`./`・`../`・`~/` で始まるパスのほかに、
  `docs/adr/0085-….md` のような `./` の無い相対パスも見つける。Cmd を押しながらクリックすると開く。
- 相対パスは、端末の今のディレクトリ (シェルが OSC 7 で知らせたもの) を元に絶対パスに直し、そのファイルがあれば `open` で開く
  (`src/Surface.zig` の `resolvePathForOpening`)。無ければ、見つけた文字をそのまま `open` に渡す (開けない)。
  - そのため、`foo.md:12` のように行番号が付いたものは、`:12` を含めてファイルの名前とみなし、開けない。
  - リンクの規則を自分で足す設定 (`link`) は、1.4.0 ではまだ使えない (ドキュメントに「TODO: This can't currently be set!」とある)。
- OSC 7 は `file://<ホスト><パス>` か `kitty-shell-cwd://<ホスト><パス>` を受け付ける。ホストは、このマシンのものでなければ無視する
  (`src/termio/stream_handler.zig` の `reportPwd`)。タイトルを受け取っていなければ、今のディレクトリをウィンドウのタイトルにする。
- Ghostty のシェルインテグレーション (zsh) は、プロンプトを出す前と `cd` の後に OSC 7 (`kitty-shell-cwd://$HOST$PWD`) を出す。
  ただし、Ghostty が直接起動したシェルだけに入り、tmux の中のシェルには入らない (`src/shell-integration/zsh/ghostty-integration` の冒頭)。
- 本人は Ghostty の中で tmux を使う。tmux は、ペインの中のシェルが出した OSC 7 を、ペインのパス (`pane_path`) として覚えるだけで、
  Ghostty には渡さない (tmux のソースの `input.c` の `input_osc_7`。ghq で取得した `a73616d`)。そのため Ghostty の今のディレクトリは、
  tmux を起動したときのままになり、tmux の中で `cd` した後の相対パスは開けないか、別のファイルを開くとみられる (試してはいない)。
- tmux の `allow-passthrough` は `on` にしてある ([ADR 0054](0054-tmux-allow-passthrough.md))。ペインのプログラムは、`\ePtmux;…\e\\` で包んだ
  エスケープシーケンスを、tmux を通り越して Ghostty に送れる (中の ESC は 2 つ重ねる)。`on` では、見えているペインからのものだけを通す (tmux(1))。
- 別の方法として、コマンドがパスを OSC 8 のリンク (絶対パスの `file://`) で出せば、今のディレクトリに左右されずに開ける。
  tmux は OSC 8 を Ghostty に渡す設定にしてあり (`terminal-features` の `hyperlinks`。[ADR 0057](0057-remaining-improvements-2.md))、eza は `e` などのエイリアスで `--hyperlink` を付けている。
  - ripgrep 15.2.0 は `--hyperlink-format` でリンクを出す (`default` は `file://{host}{path}`)。標準出力が端末でないときは、指定しても出さない。
    設定ファイルは、環境変数 `RIPGREP_CONFIG_PATH` で指すものだけを読む (今は設定していない)。
  - fd 10.5.0 は `--hyperlink[=auto|always|never]` でリンクを出す (`auto` は色を付けるときだけ。既定は `never`)。設定ファイルは無い。

## 実装すること

- tmux の中の zsh から、Ghostty に OSC 7 を送る。
  - `zsh/lib/tmux-osc7.zsh` を足す。純粋な関数 `tmux_osc7_sequence <ホスト> <パス>` が、
    `kitty-shell-cwd://<ホスト><パス>` の OSC 7 を tmux の passthrough で包んだ文字列 (`\ePtmux;\e\e]7;…\a\e\\`) を返す。
    ホストとパスの制御文字は取り除く (Ghostty のシェルインテグレーションと同じ)。`kitty-shell-cwd` は、パスを百分率符号化せずに送れる。
  - `$TMUX` があるときだけ、`precmd` と `chpwd` で、端末 (`/dev/tty`) にこの文字列を書く。`add-zsh-hook` で登録する。
  - `zsh/zshrc` で読む。
- ripgrep の設定ファイル `ripgrep/config` を置き、`--hyperlink-format=default` を書く。`zsh/zshenv` で `RIPGREP_CONFIG_PATH` を
  `$DOTFILES/ripgrep/config` にする。
- `zsh/aliases.sh` に、fd があるときに `alias fd='fd --hyperlink=auto'` を足す。
- `docs/specifications.md` の Ghostty と zsh の節に書く。

## 実装しないこと

- 行番号の付いたパス (`foo.md:12`) を nvim で開くこと (Ghostty の今の機能ではできない)。
- Ghostty のシェルインテグレーションを、tmux の中のシェルでも読むこと (tmux の中では OSC 7 が tmux に吸われるので、効かない)。
- tmux の外 (Ghostty が直接起動したシェル) の OSC 7 (Ghostty のシェルインテグレーションが送る)。
- ペインを切り替えたときに、すぐに今のディレクトリを送り直すこと (tmux の hook などで送る)。
- ssh の先のシェルからの OSC 7 (Ghostty がホストで無視する)。
- `ls` (macOS の `/bin/ls`。リンクを出せない) と、git などほかのコマンドのリンク。

## テスト設計

先にテストを書いて失敗させてから実装する。

- `zsh/tests/tmux-osc7.test.zsh` を足す。
  - `tmux_osc7_sequence dione4.local /Users/a/b` が、`$'\ePtmux;\e\e]7;kitty-shell-cwd://dione4.local/Users/a/b\a\e\\'` を返すこと。
  - 空白・日本語を含むパスはそのまま入ること。ホスト・パスの制御文字 (ESC・BEL) は取り除かれること。
  - `$TMUX` があるとき、`precmd`・`chpwd` の関数が、書き込み先 (テストでは作業用のファイルに差し替える) に上の文字列を書くこと。
    `$TMUX` が無いときは何も書かないこと。
  - 読み込むと `precmd_functions`・`chpwd_functions` に登録され、2 回読み込んでも 1 回だけであること。
- `rg` の設定の確かめ: `RIPGREP_CONFIG_PATH=ripgrep/config rg --color=always <語> <ファイル>` の出力に OSC 8 (`\e]8;;file://`) が含まれ、
  パイプに出すとき (`| cat`) は含まれないこと。
- 本人が確かめる (Ghostty の中の tmux で):
  - `cd` で別のディレクトリに移り、相対パス (`ls` の出力のファイル名を含む `./<名前>`、`docs/adr/0085-….md` など) を Cmd+クリックすると開くこと。
  - `rg`・`fd` の出力のパスを Cmd+クリックすると開くこと。
  - tmux のペインを左右に分け、それぞれ別のディレクトリにいるとき、プロンプトを出した方のディレクトリが使われること。
  - Ghostty のウィンドウのタイトルが変わらないこと (変わるなら、トレードオフに書き足す)。
- 既存の zsh のテストと、CI の shellcheck が通ること。

## トレードオフ

- Ghostty の今のディレクトリは、見えているペインのうち、最後にプロンプトを出した (または `cd` した) ものになる。ペインを切り替えた直後は、
  切り替えた先でプロンプトを出すまで、前のペインのディレクトリのまま。
- プロンプトを出すたびに、端末に短いエスケープシーケンスを書く。
- Ghostty がタイトルを受け取っていないと、今のディレクトリがウィンドウのタイトルになる (tmux は `set-titles off`)。
- `rg` の結果がリンクになり、`fd` も、エイリアスを使う対話のシェルではリンクになる。スクリプトの中や、パイプに出すときは出ない。

## 参考文献

- Ghostty の `v1.4.0` のソース: `src/config/url.zig`、`src/Surface.zig` (`resolvePathForOpening`・`processLinks`)、
  `src/termio/stream_handler.zig` (`reportPwd`)、`src/shell-integration/zsh/ghostty-integration`: https://github.com/ghostty-org/ghostty
- Ghostty の設定のドキュメント (`ghostty +show-config --default --docs` の `link`・`link-url`・`link-osc8`)
- tmux のソースの `input.c` (`input_osc_7`。`a73616d`): https://github.com/tmux/tmux
- tmux(1) の `allow-passthrough` (tmux 3.8)
- ripgrep の `rg --help` の `--hyperlink-format` (15.2.0)
- fd の `fd --help` の `--hyperlink` (10.5.0)
