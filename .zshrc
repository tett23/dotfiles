export DOTFILES=~/dotfiles

source $DOTFILES/zsh/exports.sh
source $DOTFILES/zsh/prezto.sh
source $DOTFILES/zsh/common.sh
source $DOTFILES/zsh/vcs.sh
source $DOTFILES/zsh/aliases.sh
source $DOTFILES/zsh/colors.sh
source $DOTFILES/zsh/prompt.sh
source $DOTFILES/zsh/fzf.sh
source $DOTFILES/zsh/brew.sh

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
source ~/.rvm/scripts/rvm
source ~/.nvm/nvm.sh

eval "$(direnv hook zsh)"

if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

## load user .zshrc configuration file
[ -f ~/.zshrc.mine ] && source ~/.zshrc.mine

source ~/.fzf.zsh

