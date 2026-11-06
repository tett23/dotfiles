# ADR 0079: コマンドの監査 (2026-11-04) の結果を直す

ステータス: 採択

## 文脈

本人から、ベストプラクティスに沿っていないものや古いコマンドを使っているものを監査し、ADR にまとめるよう要望があった。
結果は [コマンドの監査 (2026-11-04)](../audit/2026-11-04-commands.md) にまとめた。壊れているものが 3 つ (K1〜K3)、古い書き方などが 7 つ (O1〜O7) あった。

- K1 は今まさに壊れている。Docker 29 の `docker images` では、3 列目がイメージの ID ではなく大きさ (`DISK USAGE`) になっている (手元で確かめた)。
- K2・K3 は、`git branch` の表示用の出力を加工している。git は、表示用の出力の形を保証せず、スクリプトには `--format` や `for-each-ref` を勧めている。
- O6 (`GOPATH`) は、変えると `go install` で入れたコマンドの置き場所が変わるので、本人の判断が要る。

## 実装すること

| ID | 変更 |
|---|---|
| K1 | `__docker_image_id` を `docker image ls --format '{{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.CreatedSince}}\t{{.Size}}'` にし、1 列目を ID として取る。`__docker_container_id` も同じく `docker ps --format '{{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}'` にする |
| K2 | `delete-merged-branches` を、`git branch --merged --format='%(HEAD) %(worktreepath) %(refname:short)'` から、今のブランチ (`*`)・ほかの worktree で使っているブランチ・`main`・`master`・`develop` を除いて `git branch -d` する形にする |
| K3 | `__fbr` の一覧を `git for-each-ref --sort=committerdate --format='%(refname:short)' refs/heads refs/remotes` で作り、`<リモート>/HEAD` だけを除く (並び順は今と同じく古い順) |
| O1 | `co` を `switch`、`cob` を `switch -c` にする |
| O2 | `tmux/statuses.conf` の `#(whoami)@#h` を `#{user}@#h` にする |
| O3 | `bootstrap.sh` の Nix のインストーラを v3.24.1 にする |
| O4 | `zsh/fzf.sh` の `[ "x…" != "x" ]` を `[[ -n … ]]` に、`echo $pid \| xargs kill` を `kill` に直し、`__find_pid` の変数を `local` にし、`__fkill`・`__find_pid`・`__find_node_modules`・`__yarn_workspaces` の `fzf` を `_fzf_run` にする |
| O5 | `zsh/aliases.sh` の `sed="gsed"`・`diff='colordiff -u'`・`python="python3"` のエイリアスを消す (`colordiff` は使っていないと本人が確かめた) |
| O7 | `bin/orch` の `cleanup` で、worktree を `rm -rf` で消した後に `git worktree prune` を実行し、ウィンドウを `orch-<セッション>` などセッションを付けた指定で閉じる |

- `docs/specifications.md` の関係する記述 (git のエイリアス、fzf のコマンド) を直す。

## 実装しないこと

- O6 (`GOPATH`)。本人が判断するまで変えない。
- エイリアスの名前の変更 (`co`・`cob` のまま)。
- 監査で問題が無かったものの変更。

## テスト設計

先にテストを書いて失敗させてから実装する (自動テストにできるもの)。

- K3: `zsh/tests/` に、作業用のリポジトリ (ブランチ `feature/HEAD-like`、リモートの `origin/HEAD` を含む) で `__fbr` の一覧の元になる部分を確かめるテストを足す。
  一覧を作る処理を純粋な関数 (`fzf_branch_names`) に切り出し、`origin/HEAD` だけが除かれ、名前に `HEAD` を含むブランチは残ることを確かめる。
- K2: `zsh/tests/` に、作業用のリポジトリで、マージ済みのブランチ・ほかの worktree で使っているマージ済みのブランチ・`main` を作り、
  `git delete-merged-branches` が、worktree のものと `main` を残して、ほかのマージ済みのブランチだけを消すこと、エラーにならないことを確かめるテストを足す
  (テストではリポジトリの `git/config` を `GIT_CONFIG_GLOBAL` で読む)。
- K1: 手元の Docker で、`__docker_image_id --filter <イメージ>` (fzf の `--filter`) がイメージの ID を返すこと、`__docker_container_id` がコンテナの ID を返すことを確かめる。
- O1・O2・O3・O5・O7: 値の変更なので、自動テストは書かない。`git co`・`git cob` が動くこと、tmux のステータスラインに `ユーザー名@ホスト名` が出ること、
  `bootstrap.sh` の URL が v3.24.1 で取得できること (`curl -fsSI`)、新しい zsh でエイリアスが無いこと (`whence -w`)、shellcheck が通ることを確かめる。
- O4: 既存の zsh のテストと、`fkill`・`find_pid` を `--filter` で動かして確かめる。
- 既存の zsh のテストと CI の shellcheck が通ること。

## トレードオフ

- K1: fzf の一覧の列が、Docker の既定の表示と違う並びになる。
- K2: `main`・`master`・`develop` のほかに残したいブランチがあっても、今どおり消える。
- O7: `orch` の動きが少し変わる (ほかのセッションの同じ名前のウィンドウを閉じなくなる)。

## 参考文献

- git-branch(1) の `--format`、git-for-each-ref(1)、git-switch(1): https://git-scm.com/docs
- Docker の `docker image ls` の `--format`: https://docs.docker.com/reference/cli/docker/image/ls/
- tmux(1) の書式の変数 (`user`): https://man.openbsd.org/tmux.1
- Determinate Systems の nix-installer のリリース: https://github.com/DeterminateSystems/nix-installer/releases
