" アンチエイリアス
set antialias
" font
if has('xfontset')
"  set guifontset=a14,r14,k14
elseif has('mac')
  set guifont=Monaco:h10
elseif has('win32') || has('win64')
"  set guifont=MS_Gothic:h11:cSHIFTJIS
"  set guifontwide=MS_Gothic:h11:cSHIFTJIS
endif
