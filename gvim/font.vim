" アンチエイリアス
set antialias
" font
if has('xfontset')
"  set guifontset=a14,r14,k14
elseif has('mac')
  "set guifontwide=Hiragino\ Maru\ Gothic\ ProN\ W4:h10
  set guifont=MonacoForPowerline:h14
  set guifontwide=YuGo-Medium:h14
  set ambiwidth=double
  set guioptions=emg
elseif has('win32') || has('win64')
  set guifont=Ubuntu\ Mono\ for\ Powerline:h8
  set guifontwide=MigMix\ 1M:h8:cSHIFTJIS
  "set guifont=MS_Gothic:h9:cSHIFTJIS
  "set guifont=MS_Mincho:h12:cSHIFTJIS
  " 行間隔の設定
  set linespace=1
  " 一部のUCS文字の幅を自動計測して決める
  if has('kaoriya')
    set ambiwidth=auto
  endif
endif
