# プロンプトの git 表示を psvar に入れる (docs/adr/0011)
#   psvar[1]: "[ブランチ] ++!!" (vcs_info の formats '[%b] %c%u' と同じ形)
#   psvar[2]: "& <stash 数>" (stash があるときだけ)
#
# よくある場合 (ブランチ上で、rebase などの途中でない) は git status 1 回で済ませ、
# それ以外は従来どおり vcs_info に任せる。git リポジトリの外では git を起動しない。

autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr "++"
zstyle ':vcs_info:*' unstagedstr "!!"
zstyle ':vcs_info:*' formats '[%b] %c%u'
zstyle ':vcs_info:*' actionformats '[%b|%a] %c%u'

# カレントディレクトリから親へたどって git ディレクトリを探す (外部コマンドを使わない)。
# 見つかれば REPLY に git ディレクトリを入れて 0 を返す
__git_prompt_find_git_dir() {
  local dir=$PWD line gitdir
  while :; do
    if [[ -d $dir/.git ]]; then
      REPLY=$dir/.git
      return 0
    fi
    if [[ -f $dir/.git ]]; then
      read -r line < $dir/.git
      [[ $line == gitdir:\ * ]] || return 1
      gitdir=${line#gitdir: }
      [[ $gitdir == /* ]] || gitdir=$dir/$gitdir
      REPLY=$gitdir
      return 0
    fi
    [[ $dir == / ]] && return 1
    dir=${dir:h}
  done
}

# rebase / merge / cherry-pick / revert / bisect などの途中か (vcs_info がアクションを表示する状態)
__git_prompt_in_action() {
  local gitdir=$1 f
  for f in rebase-apply rebase-merge MERGE_HEAD BISECT_LOG CHERRY_PICK_HEAD REVERT_HEAD sequencer .dotest .dotest-merge; do
    [[ -e $gitdir/$f ]] && return 0
  done
  return 1
}

# 従来の実装 (vcs_info + git stash list)
__git_prompt_slow() {
  LANG=en_US.UTF-8 vcs_info
  [[ -z "$vcs_info_msg_0_" ]] && return
  psvar[1]="$vcs_info_msg_0_"

  local stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
  if [ "$stash_count" -gt 0 ]; then
    psvar[2]="& $stash_count"
  fi
}

__git_prompt_update() {
  psvar=()
  local REPLY
  __git_prompt_find_git_dir || return

  if [[ -n ${GIT_DIR-} ]] || __git_prompt_in_action $REPLY; then
    __git_prompt_slow
    return
  fi

  local out
  out=$(git status --porcelain=v2 --branch --show-stash -uno --ignore-submodules=dirty 2>/dev/null) || {
    __git_prompt_slow
    return
  }

  local branch= staged= unstaged= stash=0 line xy
  for line in ${(f)out}; do
    case $line in
    '# branch.oid (initial)') __git_prompt_slow; return ;;
    '# branch.head '*) branch=${line#\# branch.head } ;;
    '# stash '*) stash=${line#\# stash } ;;
    '1 '* | '2 '*)
      xy=${line[3,4]}
      [[ ${xy[1]} != . ]] && staged=++
      [[ ${xy[2]} != . ]] && unstaged=!!
      ;;
    'u '*) __git_prompt_slow; return ;;
    esac
  done

  if [[ -z $branch || $branch == '(detached)' ]]; then
    __git_prompt_slow
    return
  fi

  psvar[1]="[$branch] $staged$unstaged"
  (( stash > 0 )) && psvar[2]="& $stash"
}
