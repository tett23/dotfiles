test -s ~/.vimrc && unlink ~/.vimrc
ln -s dotfiles/.vimrc ~/.vimrc
test -s ~/.gvimrc && unlink ~/.gvimrc
ln -s dotfiles/.gvimrc ~/.gvimrc
test $SHELL != '/bin/zsh' && chsh -s /bin/zsh
git submodule init
git submodule update
mkdir -p ~/.vim/bundle
test -s ~/.vim/bundle/neobundle.vim && unlink ~/.vim/bundle/neobundle.vim
ln -s dotfiles/vim/neobundle.vim/ ~/.vim/bundle/neobundle.vim
test -s ~/.zshrc && unlink ~/.zshrc
ln -s dotfiles/.zshrc ~/.zshrc
test -s ~/.byobu && unlink ~/.byobu
ln -s dotfiles/byobu ~/.byobu
test -s ~/.tmux-powerlinerc && unlink ~/.tmux-powerlinerc
ln -s dotfiles/tmux/powerlinerc.sh ~/.tmux-powerlinerc
test -s ~/.gitconfig && unlink ~/.gitconfig
ln -s dotfiles/.gitconfig ~/.gitconfig
test -s ~/.gitignore_global && unlink ~/.gitignore_global
ln -s dotfiles/.gitignore_global ~/.gitignore_global
test -s ~/.Xresources && unlink ~/.Xresources
ln -s dotfiles/Xresources-zenburn ~/.Xresources
