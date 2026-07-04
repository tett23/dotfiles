-- telescope.nvim (旧 fzf / fzf.vim / unite を置換)
return {
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
}
