-- lualine.nvim (旧 lightline / lightline-ale を置換)
return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        icons_enabled = true,
        theme = "auto",
        section_separators = "",
        component_separators = "",
      },
      sections = {
        lualine_c = { { "filename", path = 1 } },
        lualine_x = {
          -- カーソル位置の文字コード (旧 statusline の code:%B 相当)
          function()
            local ch = vim.fn.strcharpart(vim.fn.strpart(vim.fn.getline("."), vim.fn.col(".") - 1), 0, 1)
            if ch == "" then
              return ""
            end
            return string.format("U+%04X", vim.fn.char2nr(ch))
          end,
          "diagnostics",
          "encoding",
          "filetype",
        },
      },
    },
  },
}
