export DOTFILES=~/dotfiles

source $DOTFILES/zsh/exports.sh
source $DOTFILES/zsh/oh-my-zsh.sh
source $DOTFILES/zsh/common.sh
source $DOTFILES/zsh/vcs.sh
source $DOTFILES/zsh/aliases.sh
source $DOTFILES/zsh/colors.sh
source ~/.nvm/nvm.sh

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
source ~/.rvm/scripts/rvm

if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

PROMPT="[%n@%m %~]$ "

## load user .zshrc configuration file
[ -f ~/.zshrc.mine ] && source ~/.zshrc.mine

source ~/.fzf.zsh

