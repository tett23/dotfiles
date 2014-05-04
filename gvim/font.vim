" アンチエイリアス
set antialias
" font
if has('xfontset')
"  set guifontset=a14,r14,k14
elseif has('mac')
  "set guifontwide=Hiragino\ Maru\ Gothic\ ProN\ W4:h10
  set guifont=MonacoForPowerline:h10
  set guifontwide=YuGo-Medium:h10
  set ambiwidth=double
  set guioptions=emg
elseif has('win32') || has('win64')
"  set guifont=MS_Gothic:h11:cSHIFTJIS
"  set guifontwide=MS_Gothic:h11:cSHIFTJIS
endif
