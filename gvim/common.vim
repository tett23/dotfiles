" クリップボード
set clipboard=unnamed

set nobackup
set noswapfile
set backupdir=~/.vim/tmp

"日本語の行の連結時には空白を入力しない。
set formatoptions+=mM

"□や○の文字があってもカーソル位置がずれないようにする。
set ambiwidth=double

"画面最後の行をできる限り表示する。
set display+=lastline

" IM制御
set noimdisableactivate

" 最終行の表示
set display+=lastline

" ベルを無効
set visualbell t_vb=

if has('mac')
  noremap! ¥ \
  noremap! \ ¥
endif
