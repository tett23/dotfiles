-- カラースキーム (旧 vim/colors.vim の molokai → monokai.nvim → 保守されている monokai-pro.nvim。
-- 旧来の Monokai に近い classic フィルタを使う。docs/adr/0009)
return {
  {
    "loctvl842/monokai-pro.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("monokai-pro").setup({
        filter = "classic",
        override = function()
          return {
            Visual = { bg = "#55564e" }, -- 選択範囲 (docs/adr/0026)
            -- 不可視文字 (listchars と全角スペース)。既定の色は暗すぎて気づけない (docs/adr/0028)
            Whitespace = { fg = "#919288" },
            NonText = { fg = "#919288" },
            ZenkakuSpace = { bg = "#919288" },
          }
        end,
      })
      vim.opt.background = "dark"
      vim.cmd.colorscheme("monokai-pro")
    end,
  },
}
