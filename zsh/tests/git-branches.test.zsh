#!/usr/bin/env zsh
# ブランチの一覧を扱うもののテスト (docs/adr/0079)。使い方: zsh zsh/tests/git-branches.test.zsh
#   K3: zsh/fzf.sh の fzf_branch_names (fbr の一覧)
#   K2: git/config の delete-merged-branches
emulate -L zsh
setopt no_unset

local root=${0:A:h:h:h}
source $root/zsh/fzf.sh
local work=$(mktemp -d "${TMPDIR:-/tmp}/git-branches-test.XXXXXX")
trap "command rm -rf -- ${(q)work}" EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com

local -i failures=0
check() {
  if [[ $2 == $3 ]]; then print -r -- "PASS $1"; else print -r -- "FAIL $1 expected=${(q+)3} actual=${(q+)2}"; (( failures++ )); fi
}

# 作業用のリポジトリ: main と、マージ済みのブランチ、名前に HEAD を含むブランチ、リモート (origin/HEAD を含む)
local repo=$work/repo
git init -q -b main $repo
cd $repo
git commit -q --allow-empty -m init
git branch merged-a
git branch feature/HEAD-like
git branch in-worktree
git init -q --bare $work/remote.git
git remote add origin $work/remote.git
git push -q origin main feature/HEAD-like 2>/dev/null
git remote set-head origin main >/dev/null

check "K3: origin/HEAD だけを除き、名前に HEAD を含むブランチは残す" \
  "$(fzf_branch_names | sort | tr '\n' ' ')" \
  "feature/HEAD-like in-worktree main merged-a origin/feature/HEAD-like origin/main "

# K2: ほかの worktree で使っているマージ済みのブランチと main を残し、ほかのマージ済みのブランチだけを消す
git worktree add -q $work/wt in-worktree
git branch other
local out code
out=$(GIT_CONFIG_GLOBAL=$root/git/config git delete-merged-branches 2>&1); code=$?
local sha=$(git rev-parse --short main)
check "K2: エラーにならず、マージ済みのブランチだけを消す" "$code $out" "0 Deleted branch feature/HEAD-like (was $sha).
Deleted branch merged-a (was $sha).
Deleted branch other (was $sha)."
check "K2: worktree のブランチと main を残し、ほかのマージ済みのブランチを消す" \
  "$(git for-each-ref --format='%(refname:short)' refs/heads | sort | tr '\n' ' ')" \
  "in-worktree main "

print
(( failures > 0 )) && { print "$failures failed"; exit 1 }
print "all passed"
