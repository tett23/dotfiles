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
RPROMPT="${VCS_INFO}"
