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

# zshのバージョンをチェックする
autoload -Uz is-at-least
if is-at-least 4.3.7; then
  # バージョン管理関連の表示用
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info

  zstyle ':vcs_info:*' enable git svn hg bzr
  zstyle ':vcs_info:*' check-for-changes true
  zstyle ':vcs_info:*' stagedstr "++"
  zstyle ':vcs_info:*' unstagedstr "!!"
  zstyle ':vcs_info:*' formats '[%b] %c%u'
  zstyle ':vcs_info:*' actionformats '[%b|%a] %c%u'

  function _update_vcs_info_msg() {
    psvar=()
    LANG=en_US.UTF-8 vcs_info
    [[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"

    local stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
    if [ "$stash_count" -gt 0 ]; then
      psvar[2]="& $stash_count"
    fi
  }

  add-zsh-hook precmd _update_vcs_info_msg
  VCS_INFO="%1(v|%F{green}%1v%f%F{yellow}%2v%f|)"
fi

# パス表示: 4階層を超えたら「先頭1階層/…/末尾3階層」に短縮 (旧 short-pwd 相当、fork しない)
PROMPT='${PROMPT_KEYMAP} '"${VCS_INFO}"' [%n@%m %(5~|%-1~/…/%3~|%~)]$ '

# zsh line editor mode
function zle-line-init zle-keymap-select {
  __update_keymap_indicator
  zle reset-prompt
}

zle -N zle-line-init
zle -N zle-keymap-select
