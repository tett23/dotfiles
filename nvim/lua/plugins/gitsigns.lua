-- Git: gitsigns.nvim (旧 vim-gitgutter を置換) + fugitive
return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G" },
  },
}
