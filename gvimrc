if $DOTFILES ==# ''
  let $DOTFILES = $HOME.'/dotfiles'
end

let $PYTHONHOME = $HOME.'/.pyenv/versions/3.6.5/'

source $DOTFILES/gvim/common.vim
source $DOTFILES/gvim/window.vim
source $DOTFILES/gvim/restore_window.vim
source $DOTFILES/gvim/font.vim
source $DOTFILES/gvim/text.vim
source $DOTFILES/vim/colors.vim
