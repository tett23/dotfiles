" syntastic設定
let g:syntastic_enable_signs=1
let g:syntastic_mode_map = { 'mode': 'active',
  \ 'active_filetypes': [],
  \ 'passive_filetypes': ['html'] }
let g:syntastic_auto_loc_list = 1
let g:syntastic_javascript_checker = 'jshint'

au BufRead,BufNewFile, *.thor set filetype=ruby
au BufRead,BufNewFile, Capfile set filetype=ruby
au BufRead,BufNewFile, *.erubis set filetype=html
au BufNewFile,BufRead *as set ft=actionscript
