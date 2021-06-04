PROMPT="[%n@%m %~]$ "

__short_pwd() {
  if [[ -x `which shorten-path` ]]; then
    local cmd="shorten-path $(pwd)"
  else
    local cmd="pwd"
  fi

  echo -n $(eval "$cmd")
}

# zsh line editor mode
function zle-line-init zle-keymap-select {
  case $KEYMAP in
    vicmd)
      PROMPT="%{$fg_bold[green]%}N%{$reset_color%} [%n@%m $(__short_pwd)]$ "
    ;;
    main|viins)
      PROMPT="%{$fg_bold[cyan]%}I%{$reset_color%} [%n@%m $(__short_pwd)]$ "
    ;;
  esac
  zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select
