# ADR 0133: sync-deps の --switch は、差分の全体を見せて本人の確認を取ってから適用する

Status: proposed

## 文脈

`bin/sync-deps` は、`claude -p` に `dependencies.md` を読ませて `flake.nix`、`mise/config.toml`、`nix/pkgs/` を書かせ、`nix build` で確かめ、差分を見せる ([ADR 0013](0013-generate-config-from-dependencies-with-claude.md))。
`--switch` を付けると、差分があればそのまま `sudo darwin-rebuild switch` と `mise install` で適用する。

2026-11-16 のセキュリティの監査 ([docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md) の指摘 2) は、これを重大度「中」の問題として挙げた。
`claude -p` が書いた設定を、本人が中身を読む前に root で適用するためである。
見せる差分はファイルごとの変更の行数 (`--stat`) だけで、止まるのは `sudo` のパスワードを聞かれるときだけである。
`flake.nix` の `system.activationScripts` は root で動くので、Claude が入力 (`dependencies.md`、`nix search` や Homebrew の API の応答) から注入された指示に従うと、その内容が root で動く。

そのため、この ADR で、`--switch` は差分の全体を見せ、本人が確認したときだけ適用すると決める。

## 調査した事項

- `show_diff` は、生成の前の写しと今のファイルを `git --no-pager diff --no-index --stat` で比べ、ファイルごとの変更の行数だけを出す (`bin/sync-deps` の 111〜124 行)。
- `main` は、`show_diff` が差分ありを返し、`--switch` があれば、確認なしで `switch` を呼ぶ (`bin/sync-deps` の 161〜162 行)。`switch` は `sudo darwin-rebuild switch --flake "$DOTFILES#$HOST"` と `mise install --yes` を動かす (126〜137 行)。
- `claude -p` には `--permission-mode acceptEdits` を渡すので、Claude はファイルの編集を確認なしで行う (`bin/sync-deps` の 86 行)。
- `flake.nix` の `system.activationScripts` は、AquaSKK を `/Library/Input Methods` に rsync するなど、root で動く処理を持つ (`flake.nix` の 208〜212 行。監査の記録の指摘 2 と 4)。
- 差分を取る範囲は `TARGETS=(flake.nix flake.lock mise/config.toml nix)` だけである (`bin/sync-deps` の 25 行)。一方、`claude -p` には、パスの限定の無い `Write` と `Bash(git add -N:*)` を許している (29 行と 41 行)。そのため、Claude は範囲の外にファイルを作って `git add -N` し、`flake.nix` から読み込ませられる。このとき、範囲の中の差分に出るのは読み込みの 1 行だけである (精読の指摘)。
- flake は、git が追跡しているファイル (`git add -N` したものを含む) だけを読む。`bin/sync-deps` のプロンプトも、`nix/` に新しいファイルを作ったら `git add -N` するよう指示している (同じ理由。`bin/sync-deps` の 64 行)。
- 生成の前の写しは `$TMPDIR/sync-deps.XXXXXX` に置く (100 行)。パスの限定の無い `Write` で、Claude がこの写しを書き換えられるかは、確かめていない。書き換えられると、見せる差分そのものを偽れる。
- `bin/sync-deps` のテストは無い (`ls zsh/tests`)。CI の shellcheck のジョブは `bin/sync-deps` を検査している (`.github/workflows/ci.yml` の 31 行)。

## 実装すること

- 生成の前に、二つの一覧をシェルの変数に控える。
  - 作業ツリーの一覧: `git ls-files -c -o --exclude-standard` の各ファイルのパスと `git hash-object` のハッシュ。
  - 写しの一覧: 生成の前の写しの各ファイルのパスとハッシュ。
  変数はスクリプトのプロセスの中にだけあるので、Claude は書き換えられない。
- 生成と `nix build` の後に、二つの一覧を取り直して比べる。
  - 写しの一覧が変わっていれば、差分を見せずに、`生成の前の写しが変わりました` と出して終了コード 1 で終わる。
  - 作業ツリーの一覧で、`TARGETS` の外のファイルが足されたか、変わったか、消えていれば、そのパスを出して、適用せずに終了コード 1 で終わる。`--switch` が無いときも同じにする。
- `show_diff` は、差分があるとき、ファイルごとの変更の行数に続けて、生成の前の写しと今のファイルの差分の全体 (`git --no-pager diff --no-index`) を出す。上の比べ方により、ここで出る差分は、作業ツリーで変わったファイルのすべての差分である。
- `--switch` のとき、差分があれば、`switch` の前に `適用しますか? [y/N]` と聞き、端末から 1 行を読む。読んだ行が `y` か `yes` (大文字を含む) のときだけ `switch` を呼ぶ。それ以外の答え、空の行、読めないとき (端末が無いときを含む) は、適用せずに、`適用しませんでした` と出して終了コード 1 で終わる。
- 答えは、環境変数 `SYNC_DEPS_TTY` (既定は `/dev/tty`) のファイルから読む。標準入力からは読まない。
  - 標準入力から読まないのは、`yes | sync-deps --switch` のような使い方で、確認をうっかり省けないようにするためである。
  - 環境変数は、テストで答えを渡すために置く。`sync-deps` を呼ぶ人は、この変数で確認を省けるが、その人は `sudo darwin-rebuild switch` を自分で動かせるので、守る範囲は変わらない。
  - この確認が防ぐのは、`claude -p` の中の Claude が書いた設定を、本人が読まずに適用することである。`claude -p` は `sync-deps` の子のプロセスなので、`sync-deps` の環境変数を変えられない。
- 確認を省くオプション (`--yes` など) は置かない。
- `zsh/tests/sync-deps.test.zsh` を足す。`claude`、`nix`、`sudo`、`darwin-rebuild`、`mise` は、`PATH` の先頭に置いた偽のコマンドで置き換え、呼ばれた引数をファイルに記録する。
- `docs/specifications.md` の `bin/sync-deps` の行に、`--switch` は差分の全体を見せて確認を取ってから適用することを書く。
- `.claude/skills/sync-deps/SKILL.md` の `bin/sync-deps` の説明に、同じことを書く。
- [ADR 0013](0013-generate-config-from-dependencies-with-claude.md) のステータスを、`superseded [{"part":"Decision","by":["docs/adr/0133-sync-deps-confirm-before-switch.md"],"kind":"supplement"}]` にする。

## 実装しないこと

- `claude -p` に許すツールを絞り直すこと (監査の指摘 5)。`Read`、`Edit`、`Write` のパスの限定や、`nix-prefetch-url` などの通信の限定は、Claude Code の許可の書き方を確かめてから、別の ADR で決める。
- `--switch` を消すこと。確認を取れば、生成から適用までを一つのコマンドで行える利点は残る。
- `bin/update-nix` の適用の前に確認を取ること (監査の指摘 4)。`bin/update-nix` は Claude に設定を書かせないので、別に扱う。

## 不変条件

- I1: `--switch` のとき、答えが `y` か `yes` (大文字と小文字を区別しない) でなければ、`sudo`、`darwin-rebuild`、`mise install` は一度も呼ばれない。
- I2: `--switch` のとき、答えを読む前に、差分の全体が標準出力に出ている。
- I3: `--switch` が無いとき、答えは読まれず、`sudo`、`darwin-rebuild`、`mise install` は一度も呼ばれない。
- I4: 差分が無いとき、答えは読まれず、適用もしない。
- I5: `--switch` で差分があり、答えが `y` か `yes` (大文字と小文字を区別しない) のとき、`switch` を一度だけ呼ぶ。
- I6: 生成の後に、`TARGETS` の外のファイルが作業ツリーで足されたか、変わったか、消えていれば、答えは読まれず、`sudo`、`darwin-rebuild`、`mise install` は一度も呼ばれず、終了コードは 1 である。
- I7: 生成の後に、生成の前の写しが変わっていれば、答えは読まれず、適用もせず、終了コードは 1 である。

境界の入力:

| 入力 | 期待 | 不変条件 |
| --- | --- | --- |
| `--switch`、差分あり、答え `y` | 差分の全体を出した後に適用する | I2, I5 |
| `--switch`、差分あり、答え `YES` | 適用する | I5 |
| `--switch`、差分あり、答え `n` | 適用せず、終了コード 1 | I1 |
| `--switch`、差分あり、答えが空の行 | 適用せず、終了コード 1 | I1 |
| `--switch`、差分あり、`SYNC_DEPS_TTY` が無いファイル | 適用せず、終了コード 1 | I1 |
| `--switch`、差分あり、答え `y` を標準入力にだけ流す (`SYNC_DEPS_TTY` は空のファイル) | 適用せず、終了コード 1 | I1 |
| `--switch`、差分あり、答え `yy` | 適用せず、終了コード 1 | I1 |
| `--switch` なし、差分あり | 答えを読まず、適用しない | I3 |
| `--switch`、差分なし | 答えを読まず、適用しない | I4 |
| 偽の `claude` が `TARGETS` の外に `x.nix` を作って `git add -N` し、`flake.nix` に 1 行を足す | `x.nix` を出し、答えを読まず、適用せず 1 | I6 |
| 偽の `claude` が `TARGETS` の外の追跡しているファイルを消す | 適用せず 1 | I6 |
| 偽の `claude` が `.gitignore` で除いたファイルだけを作る | 止めない (flake から見えない) | I6 |
| 偽の `claude` が生成の前の写しを書き換える | 差分を見せず、適用せず 1 | I7 |

## 受けいれ条件

- A1: `zsh/tests/sync-deps.test.zsh` の、上の不変条件の番号を持つテストがすべて通る。dotfiles の CI の `zsh-tests` と shellcheck のジョブも通る。
- A2: 本人が、実際の `bin/sync-deps --switch` で、差分の全体と確認の問いが出ること、`n` で適用されないことを確かめる。

## テスト設計

- A1: 境界の入力の表の行を、それぞれテストにする。テストを先に書いて失敗させてから、スクリプトを直す。
  - テストは、`$TMPDIR` に `DOTFILES` の写し (`dependencies.md` と `flake.nix` と `mise/config.toml` だけ) を作って動かす。偽の `claude` は、差分ありのテストでは `flake.nix` に 1 行を足し、差分なしのテストでは何もしない。偽の `nix` は 0 で終わる。
  - I2 は、出力の中で、差分の行が問いの文より前にあることで確かめる。
  - I6 と I7 の偽の `claude` は、環境変数で渡したシェルの断片を動かして、範囲の外のファイルや写しを変える。写しの場所は、偽の `claude` が `TMPDIR` の下を探して見つける。
  - テストの名前は `ADR 0133 I1: …` の形にする。
- A2: 手で確かめる。実際の Claude と sudo を使うため、自動のテストにしない。

## トレードオフ

- `--switch` は、本人が端末の前にいないと適用できない。非対話で適用したいときは、`--switch` を付けずに動かし、差分を読んでから `sudo darwin-rebuild switch` を手で動かす。
- 差分の全体を読むかどうかは本人に任される。確認は、読む機会を作るだけである。
- `TARGETS` の外のファイルを変える生成は、正しいものでも適用できない。そのときは、差分を読んでから手で適用する。
- `claude -p` は、パスの限定の無い `Write` で、リポジトリの外 (ホームのシェルの設定など) を書ける。この ADR は、それを防がない。許すツールを絞る別の ADR で扱う。

## 参考文献

- dotfiles の [ADR 0013](0013-generate-config-from-dependencies-with-claude.md)
- [docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md)
