# zshのバージョンをチェックする
autoload -Uz is-at-least
if is-at-least 4.3.7; then
  # バージョン管理関連の表示用
  autoload -Uz add-zsh-hook
  autoload -Uz colors
  colors
  autoload -Uz vcs_info

  zstyle ':vcs_info:*' enable git svn hg bzr
  zstyle ':vcs_info:*' formats '(%s)-[%b]'
  zstyle ':vcs_info:*' actionformats '(%s)-[%b|%a]'
  zstyle ':vcs_info:(svn|bzr):*' branchformat '%b:r%r'
  zstyle ':vcs_info:bzr:*' use-simple true
  zstyle ':vcs_info:*' check-for-changes true
  zstyle ':vcs_info:*' stagedstr "++"    # 適当な文字列に変更する
  zstyle ':vcs_info:*' unstagedstr "!!"  # 適当の文字列に変更する
  zstyle ':vcs_info:*' formats '(%s)-[%b] %c%u'
  zstyle ':vcs_info:*' actionformats '(%s)-[%b|%a] %c%u'

  function _update_vcs_info_msg() {
    psvar=()
    LANG=en_US.UTF-8 vcs_info
    [[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"

    COUNT=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
    if [ "$COUNT" -gt 0 ]; then
      psvar[2]="& $COUNT"
    fi
  }

  # show rvm prompt like "1.9.2@gemset_name"
  #function _update_rvm_prompt {
  #  result=`rvm-prompt v g 2> /dev/null`
  #  if [ "$result" ] ; then
  #    "[$result]"
  #  fi
  #}
  #function rvm_prompt() {
  #  rvm_current = _update_rvm_prompt
  #}

  add-zsh-hook precmd _update_vcs_info_msg
  #add-zsh-hook precmd _update_rvm_prompt
  #RVM_INFO="%F{green}`rvm_prompt`%f"
  #RVM_INFO="$'%{$RVM_COLOR%}$(rvm_prompt)%{${reset_color}%}'"
  VCS_INFO="%1(v|%F{green}%1v%f%F{yellow}%2v%f|)"
fi
RPROMPT="${VCS_INFO}"
