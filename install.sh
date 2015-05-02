if [ -z "$DOTFILES" ]; then
  export DOTFILES=$HOME/dotfiles
fi

ln -s -f $DOTFILES/.vimrc $HOME/.vimrc
ln -s -f $DOTFILES/.gvimrc $HOME/.gvimrc
git submodule init
git submodule update
mkdir -p $HOME/.vim/bundle
ln -nsf $DOTFILES/vim/neobundle.vim/ $HOME/.vim/bundle/neobundle.vim
ln -nsf $DOTFILES/.zshrc $HOME/.zshrc
ln -nsf $DOTFILES/tmux/powerlinerc.sh $HOME/.tmux-powerlinerc
ln -nsf $DOTFILES/.gitconfig $HOME/.gitconfig
ln -nsf $DOTFILES/.gitignore_global $HOME/.gitignore_global
ln -nsf $DOTFILES/Xresources-zenburn $HOME/.Xresources
ln -nsf $DOTFILES/tmux.conf $HOME/.tmux.conf

$DOTFILES/zsh/fzf/install
