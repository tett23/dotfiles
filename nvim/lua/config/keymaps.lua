-- グローバルキーマップ (vim/keymap.vim から移植)
-- リーダーは init.lua でプラグインの読み込みより前に設定済み
local map = vim.keymap.set
local opts = { silent = true }

-- ; と : を入れ替える。Shift 無しの ; でコマンドラインに入る (docs/adr/0090)
map("", ";", ":")
map("", ":", ";")

-- バッファ / タブ
map("n", "<Leader>n", "<cmd>enew<CR>", opts) -- 新規バッファ
map("n", "<Leader>w", "<cmd>BufferClose<CR>", opts) -- バッファを閉じる (barbar)
map("", "<S-Tab>", "<cmd>tabnext<CR>", opts)
map("n", "<Leader>t", "<cmd>tabedit<CR>", opts) -- 新規タブ (T は flash.nvim の文字の移動に使う。docs/adr/0045)
map("", "<C-w>o", "<cmd>tabnew %<CR>", opts)

-- <C-k> でコメントトグル (Neovim 標準の gc。旧 caw.vim の <C-K>)
-- normal: 現在行 / visual: 選択範囲 (V-LINE 含む)。標準マッピングを呼ぶので remap 必須
map("n", "<C-k>", "gcc", { remap = true, silent = true })
map("x", "<C-k>", "gc", { remap = true, silent = true })

-- LSP は lspsaga.nvim のコマンドで扱う (docs/adr/0097)
map("n", "<Leader>g", "<cmd>Lspsaga hover_doc<CR>", opts) -- Hover
map("n", "<Leader>df", "<cmd>Lspsaga peek_definition<CR>", opts) -- 定義のプレビュー (<C-o> で開く)
map("n", "<Leader>rf", "<cmd>Lspsaga finder<CR>", opts) -- 参照と実装の一覧
map("n", "<Leader>rn", "<cmd>Lspsaga rename<CR>", opts) -- Rename
map("n", "<Leader>ca", "<cmd>Lspsaga code_action<CR>", opts) -- コードアクション
-- 前・次の診断へ移り、内容を浮動ウィンドウで出す (nvim の既定の [d・]d を置き換える)
map("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", opts)
map("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", opts)
-- 保存時と同じ conform で整形する。conform に整形の道具が無ければ LSP で整形する (docs/adr/0055)
map("n", "<Leader>fmt", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, opts) -- Format

-- Telescope (旧 fzf.vim / CocList を置換)
map("n", "<Leader><Leader>", "<cmd>Telescope find_files<CR>", opts)
map("n", "<Leader>ff", "<cmd>Telescope find_files<CR>", opts)
map("n", "<Leader>fg", "<cmd>Telescope live_grep<CR>", opts)
map("n", "<Leader>fb", "<cmd>Telescope buffers<CR>", opts)

-- コマンドパレット (Telescope commands)。Ghostty は Cmd+P を <D-p> として送る
map("n", "<C-p>", "<cmd>Telescope commands<CR>", opts)
map("n", "<D-p>", "<cmd>Telescope commands<CR>", opts)
