export DOTFILES=~/dotfiles

source $DOTFILES/zsh/exports.sh
source $DOTFILES/zsh/oh-my-zsh.sh
source $DOTFILES/zsh/common.sh
source $DOTFILES/zsh/vcs.sh
source $DOTFILES/zsh/aliases.sh
source $DOTFILES/zsh/colors.sh
source ~/.nvm/nvm.sh
source ~/.zsh/color

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
source ~/.rvm/scripts/rvm

fpath=(~/.zsh-completions $fpath)

PROMPT="[%n@%m %~]$ "

## load user .zshrc configuration file
[ -f ~/.zshrc.mine ] && source ~/.zshrc.mine
