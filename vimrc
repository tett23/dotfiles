if $DOTFILES ==# ''
  let $DOTFILES = $HOME.'/dotfiles'
end

if has('nvim')
  let $VIMRUNTIME = expand($XDG_CONFIG_HOME . '/nvim')
else
  let $VIMRUNTIME = expand('~/.vim')
endif

source $DOTFILES/vim/common.vim
source $DOTFILES/vim/plugins.vim
source $DOTFILES/vim/syntax.vim

" plugin config
source $DOTFILES/vim/ale.vim
source $DOTFILES/vim/colors.vim
source $DOTFILES/vim/deoplete.vim
source $DOTFILES/vim/fzf.vim
source $DOTFILES/vim/nerd_tree.vim
source $DOTFILES/vim/lightline.vim
source $DOTFILES/vim/goyo.vim
source $DOTFILES/vim/keymap.vim

" language
source $DOTFILES/vim/ruby.vim
source $DOTFILES/vim/rspec.vim
source $DOTFILES/vim/go.vim
source $DOTFILES/vim/coffee.vim

if has('nvim')
  " let $NVIM_TUI_ENABLE_TRUE_COLOR=1
endif

function! DoRemote(arg)
  UpdateRemotePlugins
endfunction

set ttimeoutlen=30

let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_smart_case = 1
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"

" カラースキームを上書きしているので最後に書いた
highlight LineNr ctermfg=gray guibg=gray

" 重いので対策
set nocursorline
set nocursorcolumn
set norelativenumber
set synmaxcol=200

" どこかでoffにしっぱなしかもしれない
syntax on
