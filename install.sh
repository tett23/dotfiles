ln -s dotfiles/.vimrc ~/.vimrc
chsh -s /bin/zsh
git submodule init
git submodule update
mkdir -p ~/.vim/bundle
ln -s dotfiles/vim/neobundle.vim/ ~/.vim/bundle/neobundle.vim
ln -s dotfiles/.zshrc ~/.zshrc
ln -s dotfiles/.byobu ~/.byobu
ln -s dotfiles/.tmux ~/.tmux
ln -s dotfiles/tmux/powerlinerc.sh ~/.tmux-powerlinerc
ln -s dotfiles/.gitconfig ~/.gitconfig
ln -s dotfiles/.gitignore_global ~/.gitignore_global
ln -s dotfiles/Xresources-hybrid ~/.Xresources
