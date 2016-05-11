" syntastic設定
let g:syntastic_enable_signs=1
let g:syntastic_mode_map = { 'mode': 'active',
  \ 'active_filetypes': [],
  \ 'passive_filetypes': ['html'] }
let g:syntastic_auto_loc_list = 1
let g:syntastic_javascript_checker = 'jshint'

" c++
let g:marching_clang_command = '/usr/bin/clang'
let g:marching#clang_command#options = {
\   "cpp" : "-std=gnu++1y"
\}

let g:marching_enable_neocomplete = 1

if !exists('g:neocomplete#force_omni_input_patterns')
  let g:neocomplete#force_omni_input_patterns = {}
endif

let g:neocomplete#force_omni_input_patterns.cpp =
  \ '[^.[:digit:] *\t]\%(\.\|->\)\w*\|\h\w*::\w*'


au BufRead,BufNewFile, *.thor set filetype=ruby
au BufRead,BufNewFile, Capfile set filetype=ruby
au BufRead,BufNewFile, *.cap set filetype=ruby
au BufRead,BufNewFile, *.erubis set filetype=html
au BufNewFile,BufRead *as set ft=actionscript
