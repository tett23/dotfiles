# 補完の候補から、git が無視するもの (.gitignore などで除外したもの) と .git を外す (docs/adr/0038)。
# zstyle -e の ignored-patterns が補完のたびに __gitignored_patterns を呼び、候補から外すパターンを作る。

# ディレクトリ $1 の直下で、git が無視するファイル・ディレクトリの名前を 1 行に 1 つ出す。
# 無視されたディレクトリは --directory で中を展開せずに 1 行にする (node_modules などが大きくても速い)。
# git のリポジトリの外や、存在しないディレクトリでは何も出さない
__gitignored_names() {
  local dir=${1:-.}
  [[ -d $dir ]] || return 0
  local -a paths
  paths=(${(f)"$(git -C $dir ls-files --others --ignored --exclude-standard --directory 2>/dev/null)"})
  # 直下のものだけを残す (末尾の / を除いて / を含まない)。src/build/ のような深い場所の行は、
  # src 自体が無視されているわけではないので外す
  paths=(${paths%/})
  paths=(${paths:#*/*})
  (( $#paths )) || return 0
  print -rl -- $paths
}

# 補完中の語 ($PREFIX) から、補完しているディレクトリを求めて、候補から外すパターンを reply に入れる。
# サブディレクトリを補完するとき (src/<Tab>) は、zsh が候補を入力中のディレクトリ付き (src/build) で照合するので、
# 名前だけの形とディレクトリ付きの形の両方を入れる
__gitignored_patterns() {
  local typed='' dir=.
  if [[ $PREFIX == */* ]]; then
    typed=${PREFIX%/*}/
    dir=${typed%/}
    [[ -z $dir ]] && dir=/
  fi
  dir=${dir/#\~/$HOME}
  local -a names=(.git ${(f)"$(__gitignored_names $dir)"})
  reply=(${(b)names})
  [[ -n $typed ]] && reply+=(${(b)typed}${(b)^names})
}

zstyle -e ':completion:*' ignored-patterns '__gitignored_patterns'
