" クリップボード
set clipboard=unnamed

"日本語の行の連結時には空白を入力しない。
set formatoptions+=mM

"□や○の文字があってもカーソル位置がずれないようにする。
set ambiwidth=double

"画面最後の行をできる限り表示する。
set display+=lastline

" IM制御
if has('noimdisableactivate')
  set noimdisableactivate
end

" 最終行の表示
set display+=lastline

" ベルを無効
set visualbell t_vb=
set belloff=all
set noerrorbells
set novisualbell

if has('mac')
  "noremap! ¥ \
  "noremap! \ ¥
endif

" 自動折り返しを無効
set tw=0
