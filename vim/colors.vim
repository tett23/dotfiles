set cursorline
" カレントウィンドウにのみ罫線を引く
augroup cch
autocmd! cch
autocmd WinLeave * set nocursorline
autocmd WinEnter,BufRead * set cursorline
augroup END

hi clear CursorLine
hi CursorLine gui=underline
highlight CursorLine ctermbg=gray guibg=gray
hi CursorColumn ctermbg=235 cterm=none

" 色の設定
set t_ut=
set t_Co=256

let g:hybrid_use_Xresources = 1
"let g:hybrid_use_iTerm_colors = 1
colorscheme molokai

hi IndentGuidesOdd ctermbg=grey
hi IndentGuidesEven ctermbg=darkgrey
