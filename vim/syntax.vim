""" indent
let g:indent_guides_start_level=2
let g:indent_guides_auto_colors=0
let g:indent_guides_color_change_percent=20
hi IndentGuidesOdd ctermbg=grey
hi IndentGuidesEven ctermbg=darkgrey
let g:indent_guides_start_lebel=1
let g:indent_guides_guide_size=1
let g:indent_guides_space_guides=1
let g:indent_guides_enable_on_vim_startup=1


"""  languages

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

  let g:go_list_type = "quickfix"
endif

set completeopt=menu,preview

au BufRead,BufNewFile, *.thor set filetype=ruby
au BufRead,BufNewFile, Capfile set filetype=ruby
au BufRead,BufNewFile, *.cap set filetype=ruby
au BufNewFile,BufRead Vagrantfile set ft=ruby
au BufRead,BufNewFile, *.erubis set filetype=html
au BufRead,BufNewFile *.as set filetype=actionscript
au BufRead,BufNewFile *.go set filetype=go
