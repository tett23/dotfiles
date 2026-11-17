# ADR 0131: orch のすべてのサブコマンドで role の名前を確かめる

Status: accepted-pending

## 文脈

`bin/orch` は、Claude から `codex exec` と `claude -p` へ作業を委譲する道具である ([ADR 0024](0024-orch-models-and-headless-install.md))。
本人は、今は委譲を GUI で行っていて、`bin/orch` をほとんど使っていない。
ただし、運用を変えることがありうるので、`bin/orch` は消さずに残す (本人の決定)。

2026-11-16 のセキュリティの監査 ([docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md) の指摘 1) は、`--role` の値の扱いを重大度「中」の問題として挙げた。
`spawn` は role の名前を確かめるが、`wait`、`collect`、`cleanup` は確かめない。
そのため、`orch cleanup --role ../../../outside` は、リポジトリの外のディレクトリを消す。
`bin/orch` を呼ぶのは LLM の司令塔なので、role の値一つでリポジトリの外を消せることになる。

残す以上、この問題は直す。
そのため、この ADR で、role の名前を受け取るすべてのサブコマンドで、`spawn` と同じ決まりで名前を確かめると決める。

## 調査した事項

- `spawn` は、`case "$role" in (*[!a-zA-Z0-9_-]*) die …` で、英数字、`_`、`-` 以外を含む名前を拒む (`bin/orch` の 111 行)。
- `--role` を受け取るのは、`spawn` (102 行)、`wait` (221 行)、`collect` (266 行)、`cleanup` (303 行) の 4 つである (`rg -n -- '--role\)' bin/orch`)。
- role のディレクトリは `role_dir()` が `$ORCH_DIR/roles/<role>` とする (59 行。`ORCH_DIR` は `.orch`)。`cleanup_role` は、`rm -rf "$ORCH_DIR/worktrees/$role"` と `rm -rf "$rdir"` を行う (281〜296 行)。
- 監査では、使い捨てのリポジトリで `orch init` の後に `orch cleanup --role ../../../outside` を動かすと、`orch: cleaned ../../../outside` を出して終了コード 0 で終わり、リポジトリの外の `outside/` が消えた (監査の記録の指摘 1)。
- `cleanup --all` は、`.orch/roles/*/` に合うディレクトリの名前を `basename` で取り、`cleanup_role` に渡し、最後に `.orch` を消す (310〜317 行)。`basename` の結果は `/` を含まず、`*` は `.` で始まる名前に合わないので、`..` にもならない。
- 4 つのサブコマンドは、どれも `--role) role="${2:-}"; shift 2 ;;` で値を読む。`--role` の後に値が無いと、`shift 2` は失敗して引数を動かさず、引数を読むループが同じ `--role` を回り続ける。精読で、使い捨てのリポジトリで `orch init` の後に `orch cleanup --role` を動かすと、2 秒後も終わっていなかった。
- `spawn` の名前の確かめは、`require_session` と、tmux と CLI の有無の確かめより前にある (`bin/orch` の 111〜117 行)。
- `bin/orch` のテストは無い (`ls zsh/tests`)。

## 実装すること

- `bin/orch` に、role の名前を確かめる関数 `validate_role` を置く。名前が空のとき、または ASCII の英数字、`_`、`-` 以外の文字を含むときは、`<サブコマンド>: role は [a-zA-Z0-9_-] のみ: '<名前>'` を標準エラーに出して終了コード 1 で終わる。
- `spawn`、`wait`、`collect`、`cleanup --role` は、引数を読んだ直後、ファイルやディレクトリやウィンドウに触れる前に、`validate_role` を呼ぶ。`spawn` の今の `case` の行は、この関数の呼び出しに置き換える。範囲の解釈がロケールで変わらないように、関数の中では `LC_ALL=C` で比べる。
- 4 つのサブコマンドで、`--role` の後に値が無いときは、`<サブコマンド>: --role には値が要ります` を出して終了コード 1 で終わる。
- `zsh/tests/orch.test.zsh` を足す。

## 実装しないこと

- `bin/orch` を消すこと、または使わなくなったものとして扱うこと (本人の決定)。
- `bin/orch` のほかの振る舞い (モデルの別名、待ち方、worktree の作り方) を変えること。
- `cleanup --all` を変えること。上の調査のとおり、`cleanup --all` が `cleanup_role` に渡す名前は、`.orch/roles/` の外を指さない。
- `rm -rf` の対象が `.orch/` の下にあるかを、パスを正規化して確かめること。名前の決まりで `/` と `.` を拒むので、`.orch/roles/` と `.orch/worktrees/` の外は指せない。

## 不変条件

- I1: `spawn`、`wait`、`collect`、`cleanup --role` に、空の名前か、ASCII の英数字、`_`、`-` 以外の文字を含む名前を渡すと、終了コード 1 で終わり、ファイル、ディレクトリ、tmux のウィンドウを一つも変えない。
- I2: ASCII の英数字、`_`、`-` だけから成る名前は、`validate_role` で拒まれない (標準エラーに名前の決まりのメッセージを出さない)。
- I3: 4 つのサブコマンドで、`--role` が最後の引数で値が無いとき、終了コード 1 で終わる。

境界の入力:

| 入力 | 期待 | 不変条件 |
| --- | --- | --- |
| `cleanup --role ../../../outside` | 1 で終わり、外のディレクトリが残る | I1 |
| `cleanup --role ..` | 1 で終わる | I1 |
| `cleanup --role a/b` | 1 で終わる | I1 |
| `wait --role ../x`、`collect --role ../x` | 1 で終わる | I1 |
| `cleanup --role ""` | 1 で終わる | I1 |
| `spawn --role ../x --model claude` | 1 で終わり、`.orch/roles/` の下に何も作らない | I1 |
| `cleanup --role` (値なし)、`wait --role` (値なし) | 1 で終わる (止まらずに終わる) | I3 |
| `cleanup --role impl-1_A` (あるもの) | 片付けて 0 で終わる | I2 |
| `.orch/roles/a/` を作ってから `cleanup --role a` | 片付けて 0 で終わる | I2 |

## 受けいれ条件

- A1: `zsh/tests/orch.test.zsh` の、上の不変条件の番号を持つテストがすべて通る。dotfiles の CI の `zsh-tests` と shellcheck のジョブも通る。

## テスト設計

- A1: 境界の入力の表の行を、それぞれテストにする。テストは `${TMPDIR:-/tmp}` の使い捨ての git のリポジトリで `orch init` を動かし、その外にディレクトリを置いて、消えないことを確かめる。tmux のウィンドウを開かないように、片付けるテストでは `spawn` を使わず、`.orch/roles/<名前>/` を直接作る。`spawn` のテストは、名前の確かめで止まる入力だけにする (tmux に触れる前に止まる)。I3 のテストは、`timeout` などで時間を区切り、終わらなければ失敗にする。テストを先に書いて失敗させてから、スクリプトを直す。テストの名前は `ADR 0131 I1: …` の形にする。

## トレードオフ

- 名前の決まりに合わない role のディレクトリを `.orch/roles/` に手で置いたときは、`cleanup --role` で片付けられない。`cleanup --all` で、セッションごと片付ける。

## 参考文献

- dotfiles の [ADR 0024](0024-orch-models-and-headless-install.md)
- [docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md)
