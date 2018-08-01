set cursorline
" カレントウィンドウにのみ罫線を引く
augroup cch
autocmd! cch
" 重いので無効にした
" autocmd WinLeave * set nocursorline
" autocmd WinEnter,BufRead * set cursorline
augroup END

" hi clear CursorLine
" hi CursorLine gui=underline
" highlight CursorLine ctermbg=gray guibg=gray
" hi CursorColumn ctermbg=235 cterm=none

" 色の設定
set t_ut=
set t_Co=256

colorscheme molokai
highlight Normal ctermbg=none
let g:molokai_original = 1
let g:rehash256 = 1
set background=dark

hi IndentGuidesOdd ctermbg=grey
hi IndentGuidesEven ctermbg=darkgrey

" highlight parenthes
let g:rainbow_active = 1
