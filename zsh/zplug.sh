source $ZPLUG_HOME/init.zsh
zplug 'zplug/zplug', hook-build:'zplug --self-manage'

zplug "mafredri/zsh-async"
zplug "zsh-users/zsh-syntax-highlighting", lazy:true
zplug "zsh-users/zsh-autosuggestions", lazy:true
zplug "zsh-users/zsh-completions", lazy:true
zplug "chrissicool/zsh-256color", lazy:true

if ! zplug check --verbose; then
  printf "Install? [y/N]: "
  if read -q; then
    echo; zplug install
  fi
fi
zplug load
