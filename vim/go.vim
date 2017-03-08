"  auto BufWritePre *.go Fmt
"  autocmd FileType go compiler go
"  au BufRead,BufNewFile *.go set filetype=go

" vim-go
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
" let g:go_highlight_fields = 1
let g:go_highlight_types = 1
" let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_structs = 1

autocmd FileType go :highlight goErr cterm=bold ctermfg=214
autocmd FileType go :match goErr /\<err\>/

let g:go_fmt_command = "goimports"
let g:go_fmt_fail_silently = 1

" deoplete-go
let g:deoplete#sources#go#gocode_binary = $GOPATH.'/bin/gocode'
let g:deoplete#sources#go#sort_class = ['package', 'func', 'type', 'var', 'const']
let g:deoplete#sources#go#use_cache = 1
