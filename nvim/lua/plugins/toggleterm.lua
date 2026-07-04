-- ターミナル (toggleterm.nvim)
return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      open_mapping = [[<c-\>]], -- Ctrl+\ でターミナルをトグル
      direction = "float",
    },
  },
}
