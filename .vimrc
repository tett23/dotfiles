if has('nvim')
  let $VIMRUNTIME = expand($XDG_CONFIG_HOME . '/nvim')
else
  let $VIMRUNTIME = expand('~/.vim')
endif

source ~/dotfiles/vim/common.vim
source ~/dotfiles/vim/dein.vim
source ~/dotfiles/vim/syntax.vim

" plugin config
source ~/dotfiles/vim/ale.vim
source ~/dotfiles/vim/lightline.vim
source ~/dotfiles/vim/colors.vim
source ~/dotfiles/vim/deoplete.vim
source ~/dotfiles/vim/ctrlp.vim

" language
source ~/dotfiles/vim/ruby.vim
source ~/dotfiles/vim/rspec.vim
source ~/dotfiles/vim/go.vim
source ~/dotfiles/vim/coffee.vim

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
