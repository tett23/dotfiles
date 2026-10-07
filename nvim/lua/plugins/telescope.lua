-- telescope.nvim (旧 fzf / fzf.vim / unite を置換)
return {
  {
    "nvim-telescope/telescope.nvim",
    version = "*", -- 最新リリース (止まっている 0.1.x ブランチは使わない。docs/adr/0009)
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
}
