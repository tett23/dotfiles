export DOTFILES=~/dotfiles

source ~/.fzf.zsh

source $DOTFILES/zsh/exports.sh
source $DOTFILES/zsh/common.sh
source $DOTFILES/zsh/colors.sh
source $DOTFILES/zsh/vcs.sh
source $DOTFILES/zsh/aliases.sh
source $DOTFILES/zsh/prompt.sh
source $DOTFILES/zsh/fzf.sh
source $DOTFILES/zsh/anyenv.sh
source $DOTFILES/zsh/completions.sh

eval "$(direnv hook zsh)"

## load user .zshrc configuration file
[ -f ~/.zshrc.mine ] && source ~/.zshrc.mine

if (which zprof > /dev/null) ;then
  zprof | less
fi
