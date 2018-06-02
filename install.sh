if [ -z "$DOTFILES" ]; then
  export DOTFILES=$HOME/dotfiles
fi

if [ -z "$XDG_CONFIG_HOME" ]; then
  export XDG_CONFIG_HOME=$HOME/.config
fi

ln -s -f $DOTFILES/.vimrc $HOME/.vimrc
ln -s -f $DOTFILES/.nvimrc $HOME/.nvimrc
ln -s -f $DOTFILES/.gvimrc $HOME/.gvimrc
ln -nsf $DOTFILES/vim $XDG_CONFIG_HOME/nvim
ln -nsf $DOTFILES/vim $HOME/.vim
mkdir -p $HOME/.vimbackup

git submodule update --init --recursive

ln -nsf $DOTFILES/zshenv $HOME/.zshenv
ln -nsf $DOTFILES/.zshrc $HOME/.zshrc
ln -nsf $DOTFILES/tmux/powerlinerc.sh $HOME/.tmux-powerlinerc
ln -nsf $DOTFILES/.gitconfig $HOME/.gitconfig
ln -nsf $DOTFILES/.gitignore_global $HOME/.gitignore_global
ln -nsf $DOTFILES/Xresources-zenburn $HOME/.Xresources
ln -nsf $DOTFILES/tmux.conf $HOME/.tmux.conf
ln -nsf $DOTFILES/exenv $HOME/.exenv
ln -nsf $DOTFILES/rvmrc $HOME/.rvmrc
ln -nsf $DOTFILES/rubocop.yml $HOME/.rubocop.yml

mkdir -p $XDG_CONFIG_HOME/brewfile
ln -nsf $DOTFILES/Brewfile $XDG_CONFIG_HOME/brewfile/Brewfile

ln -nsf $DOTFILES/karabiner $XDG_CONFIG_HOME/karabiner

command -v fzf > /dev/null
if [ ! $? ] ; then
  $DOTFILES/zsh/fzf/install
fi
