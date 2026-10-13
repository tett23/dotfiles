# ADR 0069: プロンプトの git の表示に、worktree の名前を出す

ステータス: 採択

## 文脈

zsh のプロンプトの git の表示は `[ブランチ] ++!!` の形 (`zsh/lib/git-prompt.zsh`。[ADR 0011](0011-speed-up-zsh-startup.md))。
本人から、worktree の中では `[ブランチ / worktree]` のように、どの worktree にいるかも出したいと要望があった。

- `git worktree add` で作った worktree (メインでない worktree) の最上位のディレクトリには、ディレクトリではなくファイルの `.git` があり、
  `gitdir: <メインのリポジトリの git ディレクトリ>/worktrees/<id>` と書かれている。`<id>` は、ふつうは worktree のディレクトリの名前で、
  同じ名前があると数字が付く。
- サブモジュールも `.git` のファイルを持つが、指す先は `<親の git ディレクトリ>/modules/<名前>` で、`/worktrees/` を含まない。
- 今の実装は、親へたどって `.git` を探す処理 (`__git_prompt_find_git_dir`) で、外部コマンドを使わずに git ディレクトリを求めている。
  ここで、worktree かどうかと、worktree の最上位のディレクトリも分かる。
- よくある場合は `git status` 1 回で表示を作り (速い処理)、rebase の途中や detached HEAD などは vcs_info で作る (遅い処理)。
  テスト (`zsh/tests/git-prompt.test.zsh`) は、どちらの処理でも同じ表示になることを確かめている。worktree の中で
  ブランチ上にいる場合のテストはあるが、今は `[wt] ` (ブランチ名だけ) になる。
- Claude Code の worktree (`.claude/worktrees/<名前>`) のブランチ名は `claude/<名前>` で、worktree の名前を含む。

## 実装すること

- メインでない worktree の中では、ブランチの後ろに ` / ` (前後に空白) と worktree の名前を付ける (`[ブランチ / worktree] ++!!`)。
  - worktree の名前は、worktree の最上位のディレクトリの名前 (`.git` のファイルがあるディレクトリの名前) にする。
  - 判定は、`.git` のファイルが指す git ディレクトリの親のディレクトリの名前が `worktrees` であること (サブモジュールは含まない)。
  - メインの worktree とふつうのリポジトリでは、今どおり `[ブランチ]`。
- 速い処理と遅い処理の両方で同じ形にする。遅い処理では、vcs_info の `formats`・`actionformats` (`[%b] %c%u`・`[%b|%a] %c%u`) の
  `%b` の後ろに ` / worktree` を付ける (`[%b / worktree|%a] %c%u` など)。detached HEAD でも同じ。
- `docs/specifications.md` の zsh の節に書く。

## 実装しないこと

- ブランチ名に worktree の名前が含まれるときに、省くこと (`[claude/x / x]` のように重なっても、そのまま出す)。
- worktree の名前に色を付けること (今の git の表示の色のまま)。
- `git worktree` などの外部コマンドで worktree を調べること (`.git` のファイルを読むだけにする)。

## テスト設計

`zsh/tests/git-prompt.test.zsh` に、次を足す (先に書いて失敗させてから実装する)。表示を直接比べる確認と、速い処理と遅い処理が同じになる確認の両方。

- worktree の中 (最上位とサブディレクトリ) で、`[wt / <ディレクトリの名前>] ` になること。
- worktree のディレクトリの名前と `<id>` が違う場合 (同じ名前の worktree を 2 つ作る) も、ディレクトリの名前が出ること。
- worktree の中で、変更あり (`++!!`)・detached HEAD・rebase の途中でも、` / <名前>` が付くこと。
- メインの worktree (worktree を持つリポジトリ) とサブモジュールでは付かないこと。
- 既存のテストがすべて通ること。

## トレードオフ

- worktree の中では、git の表示が長くなる。Claude Code の worktree では、ブランチ名と worktree の名前が重なって
  `[claude/<名前> / <名前>]` になる。
- 区切りの ` / ` (前後に空白) で、ブランチ名の中の `/` (`feature/x` など) と見分ける。ブランチ名に空白は使えないので、区切りと取り違えない。

## 参考文献

- git-worktree(1) の「DETAILS」(worktree の `.git` のファイルと `$GIT_COMMON_DIR/worktrees/<id>`): https://git-scm.com/docs/git-worktree#_details
- gitrepository-layout(5) の `worktrees` と `modules`: https://git-scm.com/docs/gitrepository-layout
- zsh の vcs_info (`formats`・`actionformats`): https://zsh.sourceforge.io/Doc/Release/User-Contributions.html#Version-Control-Information
