" ツールバー非表示
set guioptions-=T

" スクロールバー非表示
set guioptions-=r
set guioptions-=R
set guioptions-=l
set guioptions-=L

" メニューバー消す
if has('win32') || has('win64')
  set guioptions-=m
endif

" ウィンドウ透明度
if has('mac')
  set transparency=15
elseif has('win32') || has('win64')
  set transparency=255
endif

" コマンド高さ
set cmdheight=1
