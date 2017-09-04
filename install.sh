if [ -z "$DOTFILES" ]; then
  export DOTFILES=$HOME/dotfiles
fi

if [ -z "$XDG_CONFIG_HOME" ]; then
  export XDG_CONFIG_HOME=$HOME/.config
fi

ln -s -f $DOTFILES/.vimrc $HOME/.vimrc
mkdir -p $XDG_CONFIG_HOME/nvim
ln -s -f $DOTFILES/.nvimrc $XDG_CONFIG_HOME/nvim/init.vim
ln -s -f $DOTFILES/.gvimrc $HOME/.gvimrc

git submodule update --init --recursive

ln -nsf $DOTFILES/.zshrc $HOME/.zshrc
ln -nsf $DOTFILES/tmux/powerlinerc.sh $HOME/.tmux-powerlinerc
ln -nsf $DOTFILES/.gitconfig $HOME/.gitconfig
ln -nsf $DOTFILES/.gitignore_global $HOME/.gitignore_global
ln -nsf $DOTFILES/Xresources-zenburn $HOME/.Xresources
ln -nsf $DOTFILES/tmux.conf $HOME/.tmux.conf
ln -nsf $DOTFILES/exenv $HOME/.exenv

$DOTFILES/zsh/fzf/install
