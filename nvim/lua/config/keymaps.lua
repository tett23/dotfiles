-- グローバルキーマップ (vim/keymap.vim から移植)
-- リーダーは config/lazy.lua でプラグイン読込前に設定済み
local map = vim.keymap.set
local opts = { silent = true }

-- ; と : を入れ替え
map("", ";", ":")
map("", ":", ";")

-- バッファ / タブ
map("n", "<Leader>n", "<cmd>enew<CR>", opts) -- 新規バッファ
map("n", "<Leader>w", "<cmd>BufferClose<CR>", opts) -- バッファを閉じる (barbar)
map("", "<S-Tab>", "<cmd>tabnext<CR>", opts)
map("", "<S-t>", "<cmd>tabedit<CR>", opts)
map("", "<C-w>o", "<cmd>tabnew %<CR>", opts)

-- <C-k> でコメントトグル (Neovim 標準の gc。旧 caw.vim の <C-K>)
-- normal: 現在行 / visual: 選択範囲 (V-LINE 含む)。標準マッピングを呼ぶので remap 必須
map("n", "<C-k>", "gcc", { remap = true, silent = true })
map("x", "<C-k>", "gc", { remap = true, silent = true })

-- LSP (旧 coc.nvim マッピングを native LSP へ置換)
map("n", "<Leader>g", vim.lsp.buf.hover, opts)       -- Hover
map("n", "<Leader>df", vim.lsp.buf.definition, opts) -- Definition
map("n", "<Leader>rf", vim.lsp.buf.references, opts) -- References
map("n", "<Leader>rn", vim.lsp.buf.rename, opts)     -- Rename
map("n", "<Leader>fmt", function()
  vim.lsp.buf.format({ async = true })
end, opts) -- Format

-- Telescope (旧 fzf.vim / CocList を置換)
map("n", "<Leader><Leader>", "<cmd>Telescope find_files<CR>", opts)
map("n", "<Leader>ff", "<cmd>Telescope find_files<CR>", opts)
map("n", "<Leader>fg", "<cmd>Telescope live_grep<CR>", opts)
map("n", "<Leader>fb", "<cmd>Telescope buffers<CR>", opts)

-- コマンドパレット (Telescope commands)。Ghostty は Cmd+P を <D-p> として送る
map("n", "<C-p>", "<cmd>Telescope commands<CR>", opts)
map("n", "<D-p>", "<cmd>Telescope commands<CR>", opts)
