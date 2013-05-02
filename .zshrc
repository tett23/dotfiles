source ~/dotfiles/zsh/oh-my-zsh.sh
source ~/dotfiles/zsh/common.sh
source ~/dotfiles/zsh/exports.sh
source ~/dotfiles/zsh/vcs.sh
source ~/dotfiles/zsh/aliases.sh
source ~/dotfiles/zsh/colors.sh
source ~/.nvm/nvm.sh
source ~/.zsh/color

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
source ~/.rvm/scripts/rvm

fpath=(~/.zsh-completions $fpath)

PROMPT="[%n@%m %~]$ "

## load user .zshrc configuration file
[ -f ~/.zshrc.mine ] && source ~/.zshrc.mine
