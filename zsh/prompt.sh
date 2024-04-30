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

# zsh line editor mode
function zle-line-init zle-keymap-select {
  PROMPT="$(__keymap_name) [%n@%m $(__short_pwd)]$ "
  zle reset-prompt
}

function zle-line-finish {
  PROMPT="$(__keymap_name) [%n@%m $(__short_pwd)]$ "
  zle reset-prompt
}

zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select
