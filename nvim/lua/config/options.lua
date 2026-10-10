-- vim.opt / エディタ基本設定 (vim/common.vim から移植)
local opt = vim.opt

-- エンコーディング (encoding は Neovim では常に utf-8)
opt.fileencodings = "utf-8,ucs-bom,iso-2022-jp-3,iso-2022-jp,eucjp-ms,euc-jisx0213,euc-jp,sjis,cp932"

-- 表示
-- showmode / ruler / showcmd / wildmenu / display=lastline は Neovim の既定値なので書かない
opt.number = true
opt.title = true
opt.showmatch = true
opt.laststatus = 3 -- グローバルステータスライン (lualine)
opt.cursorline = true
opt.list = true
-- すべての半角スペースと改行も表示する。全角スペースは autocmds.lua でハイライトする (docs/adr/0028)
opt.listchars = { tab = ">-", trail = "_", nbsp = "+", space = "·", eol = "↲" }

-- ファイル (旧: nobackup / noswapfile)
opt.backup = false
opt.swapfile = false

-- インデント
opt.smartindent = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

-- 検索 (wrapscan / incsearch は既定値)
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false

-- タグ
opt.tags = "tags"

-- クリップボード共有 / マウス
opt.clipboard = "unnamed"
opt.mouse = "a"

-- 整形: デフォルトを壊さず自動改行(t)のみ無効化 (旧 formatoptions=q のバグ回避)
opt.formatoptions:remove("t")

-- grep に ripgrep を使用 (旧 grepprg のコマンド欠落バグを修正)
if vim.fn.executable("rg") == 1 then
  opt.grepprg = "rg --vimgrep --no-heading --smart-case"
  opt.grepformat = "%f:%l:%c:%m"
end
