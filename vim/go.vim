set completeopt=menu,preview

auto BufWritePre *.go Fmt
autocmd FileType go compiler go
au BufRead,BufNewFile *.go set filetype=go
