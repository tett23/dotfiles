source ~/dotfiles/vim/common.vim
source ~/dotfiles/vim/bundle.vim
source ~/dotfiles/vim/lightline.vim
source ~/dotfiles/vim/colors.vim
source ~/dotfiles/vim/neocomplecache.vim
source ~/dotfiles/vim/syntax.vim
source ~/dotfiles/vim/rspec.vim
source ~/dotfiles/vim/go.vim
source ~/dotfiles/vim/javascript.vim
source ~/dotfiles/vim/coffee.vim

let g:rsenseHome = "$RSENSE_HOME"
let g:rsenseUseOmniFunc = 1

" インデント表示
let g:indent_guides_auto_colors=0
hi IndentGuidesOdd ctermbg=grey
hi IndentGuidesEven ctermbg=darkgrey
let g:indent_guides_start_lebel=1
let g:indent_guides_guide_size=1
let g:indent_guides_enable_on_vim_startup=1
