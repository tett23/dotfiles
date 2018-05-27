let g:deoplete#enable_at_startup = 1

let g:deoplete#sources#solargraph#args = ['--port', '4424']
let deoplete#sources#solargraph#args = ['--port', '4424']


imap <C-k> <Plug>(neosnippet_expand_or_jump)
smap <C-k> <Plug>(neosnippet_expand_or_jump)
xmap <C-k> <Plug>(neosnippet_expand_target)

inoremap <expr><tab> pumvisible() ? "\<C-n>" :
        \ neosnippet#expandable_or_jumpable() ?
        \    "\<Plug>(neosnippet_expand_or_jump)" : "\<tab>"

