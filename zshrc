export DOTFILES=~/dotfiles

source $DOTFILES/zsh/exports.sh
source $DOTFILES/zsh/common.sh
source $DOTFILES/zsh/colors.sh
source $DOTFILES/zsh/vcs.sh
source $DOTFILES/zsh/aliases.sh
source $DOTFILES/zsh/prompt.sh
source $DOTFILES/zsh/fzf.sh
source $HOME/.fzf.zsh
source $DOTFILES/zsh/anyenv.sh
source $DOTFILES/zsh/completions.sh
source $DOTFILES/zsh/docker.sh
source $DOTFILES/zsh/langs/haskell.sh

eval "$(direnv hook zsh)"
