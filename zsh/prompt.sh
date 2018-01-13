PROMPT="[%n@%m %~]$ "

# zsh line editor mode
function zle-line-init zle-keymap-select {
  case $KEYMAP in
    vicmd)
    PROMPT="%{$fg_bold[green]%}N%{$reset_color%} [%n@%m %~]$ "
    ;;
    main|viins)
    PROMPT="%{$fg_bold[cyan]%}I%{$reset_color%} [%n@%m %~]$ "
    ;;
  esac
  zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select
