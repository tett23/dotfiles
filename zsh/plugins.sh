if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# プラグインは現在のコミットに固定する。更新するときは ver を書き換える (docs/adr/0010)
# fast-syntax-highlighting は compinit の後に読み込むため zshrc で読む
zinit ice ver"7a884c75b4f3ce2d8d24df8e55dcc359a020be3f"
zinit light zsh-users/zsh-completions
zinit ice ver"c3d4e576c9c86eac62884bd47c01f6faed043fc5"
zinit light zsh-users/zsh-autosuggestions
zinit ice ver"803d26eef526bff1494d1a584e46a6e08d25d918"
zinit light popstas/zsh-command-time
