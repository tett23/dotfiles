export DOTFILES=~/dotfiles

source $DOTFILES/zsh/exports.sh
source $DOTFILES/zsh/oh-my-zsh.sh
source $DOTFILES/zsh/common.sh
source $DOTFILES/zsh/vcs.sh
source $DOTFILES/zsh/aliases.sh
source $DOTFILES/zsh/colors.sh
source $DOTFILES/zsh/completion.sh
source ~/.nvm/nvm.sh

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
source ~/.rvm/scripts/rvm

fpath=(~/.zsh-completions $fpath)

if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

PROMPT="[%n@%m %~]$ "

## load user .zshrc configuration file
[ -f ~/.zshrc.mine ] && source ~/.zshrc.mine
source ~/.fzf.zsh

# Add environment variable COCOS_CONSOLE_ROOT for cocos2d-x
export COCOS_CONSOLE_ROOT=/Users/tett23/Downloads/cocos2d-x-3.8/tools/cocos2d-console/bin
export PATH=$COCOS_CONSOLE_ROOT:$PATH

# Add environment variable COCOS_TEMPLATES_ROOT for cocos2d-x
export COCOS_TEMPLATES_ROOT=/Users/tett23/Downloads/cocos2d-x-3.8/templates
export PATH=$COCOS_TEMPLATES_ROOT:$PATH

# Add environment variable COCOS_CONSOLE_ROOT for cocos2d-x
export COCOS_CONSOLE_ROOT=/Applications/Cocos/Cocos2d-x/cocos2d-x-3.10/tools/cocos2d-console/bin
export PATH=$COCOS_CONSOLE_ROOT:$PATH

# Add environment variable COCOS_X_ROOT for cocos2d-x
export COCOS_X_ROOT=/Applications/Cocos/Cocos2d-x
export PATH=$COCOS_X_ROOT:$PATH

# Add environment variable COCOS_TEMPLATES_ROOT for cocos2d-x
export COCOS_TEMPLATES_ROOT=/Applications/Cocos/Cocos2d-x/cocos2d-x-3.10/templates
export PATH=$COCOS_TEMPLATES_ROOT:$PATH
