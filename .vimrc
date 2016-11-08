source ~/dotfiles/vim/common.vim
" source ~/dotfiles/vim/bundle.vim
source ~/dotfiles/vim/dein.vim
source ~/dotfiles/vim/lightline.vim
source ~/dotfiles/vim/colors.vim
" source ~/dotfiles/vim/neocomplecache.vim
source ~/dotfiles/vim/deoplete.vim
source ~/dotfiles/vim/syntax.vim
source ~/dotfiles/vim/ruby.vim
source ~/dotfiles/vim/rspec.vim
source ~/dotfiles/vim/go.vim
source ~/dotfiles/vim/javascript.vim
source ~/dotfiles/vim/coffee.vim
source ~/dotfiles/vim/commands.vim
source ~/dotfiles/vim/keybinds.vim
source ~/dotfiles/vim/ctrlp.vim

" インデント表示
let g:indent_guides_auto_colors=0
hi IndentGuidesOdd ctermbg=grey
hi IndentGuidesEven ctermbg=darkgrey
let g:indent_guides_start_lebel=1
let g:indent_guides_guide_size=1
let g:indent_guides_enable_on_vim_startup=1

if has('nvim')
  " let $NVIM_TUI_ENABLE_TRUE_COLOR=1
endif

function! DoRemote(arg)
  UpdateRemotePlugins
endfunction

syntax on
set ttimeoutlen=30

let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_smart_case = 1
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
let g:neomake_open_list = 2
let g:neomake_ruby_enabled_makers = ['rubocop']

" カラースキームを上書きしているので最後に書いた
highlight LineNr ctermfg=gray guibg=gray
