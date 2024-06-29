export DOTFILES=~/dotfiles

source $DOTFILES/zsh/exports.sh
source $DOTFILES/zsh/common.sh
source $DOTFILES/zsh/aliases.sh
source $DOTFILES/zsh/prompt.sh
[ -f ~/.fzf.zsh ] && source $HOME/.fzf.zsh
source $DOTFILES/zsh/fzf.sh
source $DOTFILES/zsh/modern-commands.sh
source $DOTFILES/zsh/anyenv.sh
source $DOTFILES/zsh/completions.sh
source $DOTFILES/zsh/docker.sh
source $DOTFILES/zsh/langs/rust.sh
source $DOTFILES/zsh/langs/js.sh
source $DOTFILES/zsh/langs/deno.sh
source $DOTFILES/zsh/langs/go.sh
source $DOTFILES/zsh/langs/ruby.sh
source $DOTFILES/zsh/langs/swift.sh
source $DOTFILES/zsh/langs/haskell.sh

## load user .zshrc configuration file
[ -f ~/.zshrc.mine ] && source ~/.zshrc.mine

eval "$(direnv hook zsh)"
