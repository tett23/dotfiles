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
# 補完定義を足すだけの zsh-completions は compinit より前に必要なので、すぐに読み込む
zinit ice ver"7a884c75b4f3ce2d8d24df8e55dcc359a020be3f"
zinit light zsh-users/zsh-completions

# 以下は最初のプロンプトの直後に、書いた順に読み込む (turbo モード。docs/adr/0011)
# 従来 (同期読み込み) と同じ順序にする:
#   zsh-autosuggestions を読み込む → fast-syntax-highlighting が autosuggest のウィジェットも含めて包む
#   → 候補表示を開始する (従来は最初のプロンプトで開始していた)
# 遅延読み込みは compinit (zshrc) の後に走るので、fast-syntax-highlighting の
# 「compinit の後に読み込む」という条件 (docs/adr/0010) も満たす
zinit ice wait lucid ver"c3d4e576c9c86eac62884bd47c01f6faed043fc5"
zinit light zsh-users/zsh-autosuggestions
zinit ice wait lucid ver"cf318e06a9b7c9f2219d78f41b46fa6e06011fd9" atload"_zsh_autosuggest_start"
zinit light zdharma-continuum/fast-syntax-highlighting
zinit ice wait lucid ver"803d26eef526bff1494d1a584e46a6e08d25d918"
zinit light popstas/zsh-command-time
