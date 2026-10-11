# compinit はプラグイン (zinit / zsh-completions) の fpath 追加より後に実行する
# dump の検査 (遅い) は 1 日 1 回だけにし、それ以外は -C で dump をそのまま読む (docs/adr/0010)
autoload -Uz compinit
# 小文字の入力は大文字にも一致させる (大文字の入力は大文字にだけ一致する。docs/adr/0034)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
() {
  # (#q...) のグロブ修飾子は extended_glob が必要。この無名関数の中だけで有効にする
  setopt local_options extended_glob
  if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
  else
    compinit -C
  fi
}

# Tab の補完候補を fzf で絞り込む (docs/adr/0037)。compinit の後、かつウィジェットを包むプラグイン
# (zsh-autosuggestions・fast-syntax-highlighting。最初のプロンプトの後に遅延読み込み) より前に読み込む必要がある。
# プラグインは現在のコミットに固定する (docs/adr/0010)
if (( ${+functions[zinit]} )); then
  zinit ice ver"24105b15714bfec37989ed5c5b6e60f572253019"
  zinit light Aloxaf/fzf-tab
fi
# cd の補完では、候補のディレクトリの中身をプレビューする
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

# zinit 経由でロードしたプラグインの補完定義を反映する
(( ${+functions[zinit]} )) && zinit cdreplay -q
