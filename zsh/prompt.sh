PROMPT="[%n@%m %~]$ "

__short_pwd() {
  shorten-path $(pwd) 2>/dev/null || echo -n $(pwd)
}

__keymap_name() {
  case $KEYMAP in
  vicmd)
    local mode="%F{green}N%f"
  ;;
  main|viins)
    local mode="%F{cyan}I%f"
  ;;
  visual)
    local mode="%F{yellow}V%f"
  ;;
  .safe)
    local mode=""
  ;;
  esac

  echo -n $mode
}

# zshのバージョンをチェックする
autoload -Uz is-at-least
if is-at-least 4.3.7; then
  # バージョン管理関連の表示用
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info

  zstyle ':vcs_info:*' enable git svn hg bzr
  zstyle ':vcs_info:*' formats '[%b]'
  zstyle ':vcs_info:*' actionformats '[%b|%a]'
  zstyle ':vcs_info:*' check-for-changes true
  zstyle ':vcs_info:*' stagedstr "++"
  zstyle ':vcs_info:*' unstagedstr "!!"
  zstyle ':vcs_info:*' formats '[%b] %c%u'
  zstyle ':vcs_info:*' actionformats '[%b|%a] %c%u'

  function _update_vcs_info_msg() {
    psvar=()
    LANG=en_US.UTF-8 vcs_info
    [[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"

    COUNT=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
    if [ "$COUNT" -gt 0 ]; then
      psvar[2]="& $COUNT"
    fi
  }

  add-zsh-hook precmd _update_vcs_info_msg
  VCS_INFO="%1(v|%F{green}%1v%f%F{yellow}%2v%f|)"
fi

# zsh line editor mode
function zle-line-init zle-keymap-select {
  PROMPT="$(__keymap_name) ${VCS_INFO} [%n@%m $(__short_pwd)]$ "
  zle reset-prompt
}

function zle-line-finish {
  PROMPT="$(__keymap_name) ${VCS_INFO} [%n@%m $(__short_pwd)]$ "
  zle reset-prompt
}

zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select
