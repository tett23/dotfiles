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

set t_Co=256
colorscheme zenburn

let g:lightline = {
  \ 'colorscheme': 'wombat'
  \}
