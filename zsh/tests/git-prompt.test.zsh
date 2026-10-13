#!/usr/bin/env zsh
# zsh/lib/git-prompt.zsh の高速版が、従来の実装 (vcs_info) と同じ表示になるかを確かめる。
# 使い方: zsh zsh/tests/git-prompt.test.zsh
emulate -L zsh
setopt no_unset

local root=${0:A:h:h:h}
source $root/zsh/lib/git-prompt.zsh

local work=$(mktemp -d "${TMPDIR:-/tmp}/git-prompt-test.XXXXXX")
trap "command rm -r -- ${(q)work}" EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com

# 遅い処理を、プロンプトと同じく git ディレクトリと worktree の判定を経て呼ぶ (docs/adr/0069)
__git_prompt_slow_for_test() {
  local REPLY
  __git_prompt_find_git_dir || return
  __git_prompt_slow
}

local -i failures=0
check() {
  local name=$1 dir=$2 expected actual
  cd $dir
  psvar=(); __git_prompt_slow_for_test; expected="(${(j:|:)psvar})"
  psvar=(); __git_prompt_update; actual="(${(j:|:)psvar})"
  if [[ $expected == $actual ]]; then
    print -r -- "PASS $name $actual"
  else
    print -r -- "FAIL $name expected=$expected actual=$actual"
    (( failures++ ))
  fi
}

repo() {
  local d=$work/$1
  git init -q -b main $d
  print a > $d/a.txt
  git -C $d add a.txt
  git -C $d commit -q -m init
  print -r -- $d
}

mkdir $work/outside
check "outside repo" $work/outside

local r=$(repo clean)
check "clean" $r
mkdir $r/sub
check "subdirectory" $r/sub
print untracked > $r/u.txt
check "untracked only" $r

r=$(repo unstaged); print b >> $r/a.txt
check "unstaged" $r

r=$(repo staged); print b >> $r/a.txt; git -C $r add a.txt
check "staged" $r

r=$(repo both); print b >> $r/a.txt; git -C $r add a.txt; print c >> $r/a.txt
check "staged and unstaged" $r

r=$(repo stash); print b >> $r/a.txt; git -C $r stash -q; print c >> $r/a.txt; git -C $r stash -q
check "two stashes" $r

r=$(repo slash); git -C $r switch -q -c feature/x
check "branch with slash" $r

r=$(repo detached); git -C $r checkout -q --detach HEAD
check "detached HEAD" $r

r=$(repo rebase)
git -C $r switch -q -c other; print other > $r/a.txt; git -C $r commit -q -am other
git -C $r switch -q main; print main > $r/a.txt; git -C $r commit -q -am main
git -C $r rebase -q other >/dev/null 2>&1 || true
check "rebase conflict" $r

r=$(repo merge)
git -C $r switch -q -c other; print other > $r/a.txt; git -C $r commit -q -am other
git -C $r switch -q main; print main > $r/a.txt; git -C $r commit -q -am main
git -C $r merge -q other >/dev/null 2>&1 || true
check "merge conflict" $r

git init -q -b main $work/empty
check "no commits" $work/empty

r=$(repo gitdir)
check "inside .git" $r/.git

r=$(repo worktree); git -C $r worktree add -q $work/wt -b wt
check "worktree" $work/wt

r=$(repo super); local s=$(repo subm)
git -C $r -c protocol.file.allow=always submodule add -q $s sm >/dev/null 2>&1
check "submodule directory" $r/sm
check "superproject with submodule" $r

# worktree の名前の表示 (docs/adr/0069)。速い処理と遅い処理の両方が、正規表現 pattern に一致することを確かめる
expect() {
  local name=$1 dir=$2 pattern=$3 slow fast
  cd $dir
  psvar=(); __git_prompt_slow_for_test; slow=${psvar[1]-}
  psvar=(); __git_prompt_update; fast=${psvar[1]-}
  if [[ $slow =~ $pattern && $fast =~ $pattern ]]; then
    print -r -- "PASS $name $fast"
  else
    print -r -- "FAIL $name pattern=$pattern slow=$slow fast=$fast"
    (( failures++ ))
  fi
}

r=$(repo wtmain); git -C $r worktree add -q $work/wtdir -b wt
expect "worktree: branch / name" $work/wtdir '^\[wt / wtdir\] $'
mkdir $work/wtdir/sub
expect "worktree: subdirectory" $work/wtdir/sub '^\[wt / wtdir\] $'
expect "main worktree: no name" $r '^\[main\] $'

print b >> $work/wtdir/a.txt; git -C $work/wtdir add a.txt; print c >> $work/wtdir/a.txt
expect "worktree: staged and unstaged" $work/wtdir '^\[wt / wtdir\] \+\+!!$'

# 同じ名前のディレクトリの worktree を 2 つ作ると、2 つ目の id には数字が付く。表示はディレクトリの名前
mkdir $work/p1 $work/p2
git -C $r worktree add -q $work/p1/same -b same1
git -C $r worktree add -q $work/p2/same -b same2
expect "worktree: id differs from directory name" $work/p2/same '^\[same2 / same\] $'

git -C $r worktree add -q --detach $work/wtdetached
expect "worktree: detached HEAD" $work/wtdetached '^\[[^]]+ / wtdetached\] $'

git -C $r worktree add -q $work/wtrebase -b rb
git -C $work/wtrebase switch -q -c rb-other; print other > $work/wtrebase/a.txt; git -C $work/wtrebase commit -q -am other
git -C $work/wtrebase switch -q rb; print rb > $work/wtrebase/a.txt; git -C $work/wtrebase commit -q -am rb
git -C $work/wtrebase rebase -q rb-other >/dev/null 2>&1 || true
expect "worktree: rebase conflict" $work/wtrebase '^\[[^]]+ / wtrebase\|[a-z-]+\]'

r=$(repo super2); s=$(repo subm2)
git -C $r -c protocol.file.allow=always submodule add -q $s sm >/dev/null 2>&1
expect "submodule: no name" $r/sm '^\[[^] ]+\] $'

print
if (( failures > 0 )); then
  print "$failures failed"
  exit 1
fi
print "all passed"
