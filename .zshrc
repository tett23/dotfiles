export DOTFILES=~/dotfiles

source $DOTFILES/zsh/exports.sh
source $DOTFILES/zsh/common.sh
source $DOTFILES/zsh/colors.sh
source $DOTFILES/zsh/zplug.sh
source $DOTFILES/zsh/vcs.sh
source $DOTFILES/zsh/aliases.sh
source $DOTFILES/zsh/prompt.sh
source $DOTFILES/zsh/fzf.sh
source $DOTFILES/zsh/anyenv.sh

eval "$(direnv hook zsh)"

# autoload -Uz compinit
# compinit -C

## load user .zshrc configuration file
[ -f ~/.zshrc.mine ] && source ~/.zshrc.mine

source ~/.fzf.zsh

if (which zprof > /dev/null) ;then
  zprof | less
fi
