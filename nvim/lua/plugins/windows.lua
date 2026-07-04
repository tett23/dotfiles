-- ウィンドウ操作 (winresizer / windows.nvim)
return {
  -- 対話的なウィンドウリサイズ (デフォルト起動キー: <C-e>)
  { "simeji/winresizer" },

  -- カレントウィンドウを常に自動最大化 (autowidth)
  {
    "anuvyklack/windows.nvim",
    dependencies = { "anuvyklack/middleclass", "anuvyklack/animation.nvim" },
    event = "VeryLazy", -- autowidth を常時有効化するため起動時にロード
    cmd = { "WindowsMaximize", "WindowsEqualize", "WindowsToggleAutowidth" },
    config = function()
      -- フォーカス中ウィンドウを最大化 (非フォーカスは幅20に縮小)
      vim.o.winwidth = 999
      vim.o.winminwidth = 20
      vim.o.winheight = 999
      vim.o.winminheight = 1
      vim.o.equalalways = false
      require("windows").setup({
        autowidth = { enable = true }, -- カレントウィンドウを自動で最大化
      })
    end,
  },
}
