-- 編集補助 (旧 auto-pairs / indent-guides / rainbow を置換・移植)
-- コメントは Neovim 標準の gc を使う (旧 caw.vim / Comment.nvim。docs/adr/0009)
return {
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },      -- 旧 jiangmiao/auto-pairs
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} }, -- 旧 vim-indent-guides
  { "HiPhish/rainbow-delimiters.nvim" },                              -- 旧 luochen1990/rainbow
}
