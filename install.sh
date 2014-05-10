test -s ~/.vimrc && unlink ~/.vimrc
ln -s $DOTFILES/.vimrc ~/.vimrc
test -s ~/.gvimrc && unlink ~/.gvimrc
ln -s $DOTFILES/.gvimrc ~/.gvimrc
test $SHELL != '/bin/zsh' && chsh -s /bin/zsh
git submodule init
git submodule update
mkdir -p ~/.vim/bundle
test -s ~/.vim/bundle/neobundle.vim && unlink ~/.vim/bundle/neobundle.vim
ln -s $DOTFILES/vim/neobundle.vim/ ~/.vim/bundle/neobundle.vim
test -s ~/.zshrc && unlink ~/.zshrc
ln -s $DOTFILES/.zshrc ~/.zshrc
test -s ~/.tmux-powerlinerc && unlink ~/.tmux-powerlinerc
ln -s $DOTFILES/tmux/powerlinerc.sh ~/.tmux-powerlinerc
test -s ~/.gitconfig && unlink ~/.gitconfig
ln -s $DOTFILES/.gitconfig ~/.gitconfig
test -s ~/.gitignore_global && unlink ~/.gitignore_global
ln -s $DOTFILES/.gitignore_global ~/.gitignore_global
test -s ~/.Xresources && unlink ~/.Xresources
ln -s $DOTFILES/Xresources-zenburn ~/.Xresources
test -s ~/.tmux.conf && unlink ~/.tmux.conf
ln -s $DOTFILES/tmux.conf ~/.tmux.conf
