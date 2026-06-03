o = vim.o
g = vim.g

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

vim.g.mapleader = " "
vim.g.maplocalleader = "  "

keymap("n", "<Leader>g", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
keymap("n", "<Leader>df", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
keymap("n", "<Leader>rf", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
keymap("n", "<Leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
keymap("n", "<Leader>fmt", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)

keymap('', ';', ':')
keymap('', ':', ';')
keymap('n', 'j', 'gj')
keymap('n', 'k', 'gk')

keymap('n', '<Leader>w', ':w<CR>', opts)
keymap('n', '<Leader>q', ':q<CR>', opts)
keymap('n', '<Leader>wq', ':wq<CR>', opts)

keymap('', '<C-K>', '<Plug>(caw:hatpos:toggle)', opts)

-- "マッピングとか
-- map ^? ^H
-- map! ^? ^H

-- "キーマッピング
-- noremap ; :
-- noremap : ;

-- " 新規バッファ
-- nnoremap <Space>n :enew<CR>
-- nnoremap <S-w> :BD<CR>

-- " タブ
-- noremap <S-Tab> :tabn<CR>
-- noremap <S-t> :tabe<CR>
-- noremap <C-W>o :tabnew %<CR>

-- nmap <silent> <Leader><Leader> :<C-u>CocList<cr>
-- "スペースhでHover
-- nmap <silent> <space>g :<C-u>call CocAction('doHover')<cr>
-- "スペースdfでDefinition
-- nmap <silent> <space>df <Plug>(coc-definition)
-- "スペースrfでReferences
-- nmap <silent> <space>rf <Plug>(coc-references)
-- "スペースrnでRename
-- nmap <silent> <space>rn <Plug>(coc-rename)
-- "スペースfmtでFormat
-- nmap <silent> <space>fmt <Plug>(coc-format)
