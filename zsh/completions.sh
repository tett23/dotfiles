# compinit はプラグイン (zinit / zsh-completions) の fpath 追加より後に実行する
# dump の検査 (遅い) は 1 日 1 回だけにし、それ以外は -C で dump をそのまま読む (docs/adr/0010)
autoload -Uz compinit
() {
  # (#q...) のグロブ修飾子は extended_glob が必要。この無名関数の中だけで有効にする
  setopt local_options extended_glob
  if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
  else
    compinit -C
  fi
}

# zinit 経由でロードしたプラグインの補完定義を反映する
(( ${+functions[zinit]} )) && zinit cdreplay -q
