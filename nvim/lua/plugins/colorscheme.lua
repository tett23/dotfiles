-- カラースキーム (旧 vim/colors.vim の molokai → monokai.nvim → 保守されている monokai-pro.nvim。
-- 旧来の Monokai に近い classic フィルタを使う。docs/adr/0009)
return {
  {
    "loctvl842/monokai-pro.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("monokai-pro").setup({ filter = "classic" })
      vim.opt.background = "dark"
      vim.cmd.colorscheme("monokai-pro")
    end,
  },
}
