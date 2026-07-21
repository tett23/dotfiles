# compinit はプラグイン (zinit / zsh-completions) の fpath 追加より後に実行する
autoload -Uz compinit
compinit -C

# zinit 経由でロードしたプラグインの補完定義を反映する
(( ${+functions[zinit]} )) && zinit cdreplay -q
