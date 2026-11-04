# zinit 本体も、プラグインと同じくコミットに固定する。更新するときは _zinit_rev を書き換える (docs/adr/0046)
typeset -g _zinit_dir=${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git
typeset -g _zinit_rev=cb4968123979cf073384e93aa8066d8fd450580f
if [[ ! -f $_zinit_dir/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "${_zinit_dir:h}" && command chmod g-rwX "${_zinit_dir:h}"
    command git clone https://github.com/zdharma-continuum/zinit "$_zinit_dir" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi
# 固定のコミットでなければ切り替える (zinit の self-update などで動いた場合も戻す)
if [[ -d $_zinit_dir/.git && $(command git -C $_zinit_dir rev-parse HEAD 2>/dev/null) != $_zinit_rev ]]; then
    command git -C $_zinit_dir fetch -q origin $_zinit_rev 2>/dev/null
    command git -C $_zinit_dir checkout -q $_zinit_rev 2>/dev/null ||
        print -P "%F{160} zinit を固定のコミット ($_zinit_rev) に切り替えられませんでした%f"
fi

source "$_zinit_dir/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# プラグインは現在のコミットに固定する。更新するときは ver を書き換える (docs/adr/0010)
# 補完定義を足すだけの zsh-completions は compinit より前に必要なので、すぐに読み込む
zinit ice ver"989b23277ab33e8d5e82df6aed936e846db9d8b8"
zinit light zsh-users/zsh-completions

# 以下は最初のプロンプトの直後に、書いた順に読み込む (turbo モード。docs/adr/0011)
# 従来 (同期読み込み) と同じ順序にする:
#   zsh-autosuggestions を読み込む → fast-syntax-highlighting が autosuggest のウィジェットも含めて包む
#   → 候補表示を開始する (従来は最初のプロンプトで開始していた)
# 遅延読み込みは compinit (zshrc) の後に走るので、fast-syntax-highlighting の
# 「compinit の後に読み込む」という条件 (docs/adr/0010) も満たす
zinit ice wait lucid ver"85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5"
zinit light zsh-users/zsh-autosuggestions
zinit ice wait lucid ver"4672ad5dd9ad68a7effc1476d65afb7c584ce2b3" atload"_zsh_autosuggest_start"
zinit light zdharma-continuum/fast-syntax-highlighting
