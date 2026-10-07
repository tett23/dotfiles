# プロンプト内の ${...} を描画時に展開する (fork せずに動的表示するため)
setopt prompt_subst

## zle keymap (vi mode) インジケータ
# command substitution だと1行ごとに fork が発生するため、
# keymap 変更時に変数を更新して prompt_subst で参照する
typeset -g PROMPT_KEYMAP=""

__update_keymap_indicator() {
  case $KEYMAP in
  vicmd)
    PROMPT_KEYMAP="%F{green}N%f"
    ;;
  visual)
    PROMPT_KEYMAP="%F{yellow}V%f"
    ;;
  .safe)
    PROMPT_KEYMAP=""
    ;;
  main|viins|*)
    PROMPT_KEYMAP="%F{cyan}I%f"
    ;;
  esac
}
__update_keymap_indicator

## バージョン管理関連の表示 (git のみ。docs/adr/0010)
# よくある場合は git status 1 回で、それ以外は vcs_info で表示を作る (docs/adr/0011)
autoload -Uz add-zsh-hook
source $DOTFILES/zsh/lib/git-prompt.zsh
add-zsh-hook precmd __git_prompt_update
VCS_INFO="%1(v|%F{green}%1v%f%F{yellow}%2v%f|)"

# パス表示: 4階層を超えたら「先頭1階層/…/末尾3階層」に短縮 (旧 short-pwd 相当、fork しない)
PROMPT='${PROMPT_KEYMAP} '"${VCS_INFO}"' [%n@%m %(5~|%-1~/…/%3~|%~)]$ '

# zsh line editor mode
function zle-line-init zle-keymap-select {
  __update_keymap_indicator
  zle reset-prompt
}

zle -N zle-line-init
zle -N zle-keymap-select
