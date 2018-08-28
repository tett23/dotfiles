"マッピングとか
map ^? ^H
map! ^? ^H

"キーマッピング
noremap ; :
noremap : ;

" 新規バッファ
nnoremap <Space>n :enew<CR>
nnoremap <S-w> :BD<CR>

" タブ
noremap <S-Tab> :tabn<CR>
noremap <S-t> :tabe<CR>
noremap <C-W>o :tabnew %<CR>
