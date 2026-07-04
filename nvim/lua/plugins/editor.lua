-- 編集補助 (旧 auto-pairs / caw / indent-guides / rainbow / eskk を置換・移植)
return {
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },      -- 旧 jiangmiao/auto-pairs
  { "numToStr/Comment.nvim", opts = {} },                             -- 旧 caw.vim (<Leader>c 系はデフォルト gc)
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} }, -- 旧 vim-indent-guides
  { "HiPhish/rainbow-delimiters.nvim" },                              -- 旧 luochen1990/rainbow
  { "tyru/eskk.vim" },                                                -- 日本語入力 (SKK) はそのまま移植
}
