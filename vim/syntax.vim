" syntastic設定
let g:syntastic_enable_signs=1
let g:syntastic_mode_map = { 'mode': 'active',
  \ 'active_filetypes': [],
  \ 'passive_filetypes': ['html'] }
let g:syntastic_auto_loc_list = 1

" c++
let g:marching_clang_command = '/usr/bin/clang'
let g:marching#clang_command#options = {
\   "cpp" : "-std=gnu++1y"
\}

" go
if $GOPATH != ''
  " golintの実行パスを追加
  filetype off
  filetype plugin indent off
  " set runtimepath+=$GOROOT/misc/vim
  execute "set rtp+=".globpath($GOPATH, "src/github.com/golang/lint/misc/vim")
  filetype plugin indent on
  syntax on

  " syntastic設定
  let g:syntastic_go_checkers = ['golint', 'govet', 'errcheck']
  let g:syntastic_mode_map = { 'mode': 'active', 'passive_filetypes': ['go'] }
  let g:go_list_type = "quickfix"
endif

let g:marching_enable_neocomplete = 1

"  if !exists('g:neocomplete#force_omni_input_patterns')
"    let g:neocomplete#force_omni_input_patterns = {}
"  endif
"
"  let g:neocomplete#force_omni_input_patterns.cpp =
"    \ '[^.[:digit:] *\t]\%(\.\|->\)\w*\|\h\w*::\w*'


set completeopt=menu,preview

au BufRead,BufNewFile, *.thor set filetype=ruby
au BufRead,BufNewFile, Capfile set filetype=ruby
au BufRead,BufNewFile, *.cap set filetype=ruby
au BufNewFile,BufRead Vagrantfile set ft=ruby
au BufRead,BufNewFile, *.erubis set filetype=html
au BufRead,BufNewFile *.as set filetype=actionscript
au BufRead,BufNewFile *.go set filetype=go
