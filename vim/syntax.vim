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

" $RUNTIMEPATHからsyntaxの定義を探してくる
function! s:split_runtime_path(runtimepath) abort
  if stridx(a:runtimepath, '\,') < 0
    return split(a:runtimepath, ',')
  endif

  let split = split(a:runtimepath, '\\\@<!\%(\\\\\)*\zs,')
  return map(split,'substitute(v:val, ''\\\([\\,]\)'', ''\1'', ''g'')')
endfunction

let s:rtps = s:split_runtime_path(&runtimepath)

for s:item in s:rtps
  let s:syntax_path = expand(s:item . '/syntax/syntax.vim')

  " 自身をsourceすると再帰してしまうのでそのガード
  if expand('<sfile>:p') == s:syntax_path
    continue
  endif

  if filereadable(s:syntax_path)
    execute 'source ' . s:syntax_path
  endif
endfor


" どこかでoffにしっぱなしかもしれない
syntax on
