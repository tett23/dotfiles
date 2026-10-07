# シェル統合スクリプトを出力するコマンド (fzf --zsh など) の出力をキャッシュして読み込む (docs/adr/0011)
#
# 使い方: __cached_eval <キャッシュ名> <コマンド> [引数...]
#
# 呼び出すパス・実体のパス・実体の更新日時をキーにし、変わったら作り直す。
# Nix のストアのファイルは更新日時が固定なので、実体のパスの変化で更新を検出する。
# 出力に呼び出すパスが埋め込まれることがある (mise activate など) ので、呼び出すパスもキーに含める。
# 出力の中で実行時に評価される部分 (eval "$(...)" など) は、従来どおり毎回評価される。

zmodload -F zsh/stat b:zstat

__cached_eval() {
  local name=$1 cmd=$2
  shift
  local bin=${commands[$cmd]-}
  [[ -n $bin ]] || return 1

  local real=${bin:A} mtime
  zstat -A mtime +mtime -- $real 2>/dev/null || return 1
  local key="# key: $bin $real $mtime ${(j: :)@}"

  local dir=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
  local cache=$dir/$name.zsh
  local head=
  [[ -r $cache ]] && read -r head < $cache

  if [[ $head != $key ]]; then
    mkdir -p $dir
    local out
    out=$("$@") || return 1
    print -r -- "$key"$'\n'"$out" > $cache.$$ && mv -f $cache.$$ $cache
  fi
  source $cache
}
