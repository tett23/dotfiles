-- カラースキーム (旧 vim/colors.vim の molokai を treesitter 対応 monokai に置換)
return {
  {
    "tanvirtin/monokai.nvim",
    priority = 1000,
    config = function()
      vim.opt.background = "dark"
      vim.cmd.colorscheme("monokai")
    end,
  },
}
