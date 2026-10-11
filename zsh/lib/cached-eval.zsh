# シェル統合スクリプトを出力するコマンド (fzf --zsh など) の出力をキャッシュして読み込む (docs/adr/0011)
#
# 使い方: __cached_eval <キャッシュ名> <コマンド> [引数...]
#
# 呼び出すパス・実体のパス・実体の更新日時をキーにし、変わったら作り直す。
# Nix のストアのファイルは更新日時が固定なので、実体のパスの変化で更新を検出する。
# 出力に呼び出すパスが埋め込まれることがある (mise activate など) ので、呼び出すパスもキーに含める。
# 出力の中で実行時に評価される部分 (eval "$(...)" など) は、従来どおり毎回評価される。
#
# 出力のうち、PATH をその時点の値に固定する行 (行頭の `export PATH=`・`export __MISE_ORIG_PATH=`。mise activate の先頭の 2 行) は
# キャッシュに残さない。残すと、キャッシュを作った後で zsh の設定に足した PATH が、読み込むたびに古い値で消える (docs/adr/0051)。

zmodload -F zsh/stat b:zstat

__cached_eval() {
  local name=$1 cmd=$2
  shift
  local bin=${commands[$cmd]-}
  [[ -n $bin ]] || return 1

  local real=${bin:A} mtime
  zstat -A mtime +mtime -- $real 2>/dev/null || return 1
  # v2: PATH を固定する行を取り除く形式 (docs/adr/0051)。形式が変わったら版を上げて作り直させる
  local key="# key: v2 $bin $real $mtime ${(j: :)@}"

  local dir=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
  local cache=$dir/$name.zsh
  local head=
  [[ -r $cache ]] && read -r head < $cache

  if [[ $head != $key ]]; then
    mkdir -p $dir
    local out
    out=$("$@") || return 1
    local -a lines=("${(@f)out}")
    # 引用して空行も残す (複数行の文字列の中の空行が消えると、意味が変わるため)
    local -a kept=("${(@)lines:#(export PATH=|export __MISE_ORIG_PATH=)*}")
    local note="# removed: $(( $#lines - $#kept )) lines that pin PATH"
    print -r -- "$key"$'\n'"$note"$'\n'"${(F)kept}" > $cache.$$ && mv -f $cache.$$ $cache
  fi
  source $cache
}
