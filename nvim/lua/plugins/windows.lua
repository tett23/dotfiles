-- ウィンドウ操作 (winresizer / focus.nvim)
return {
  -- 対話的なウィンドウリサイズ (デフォルト起動キー: <C-e>)
  { "simeji/winresizer" },

  -- カレントウィンドウを自動で最大化する (保守の止まった windows.nvim から移行。docs/adr/0009)
  {
    "nvim-focus/focus.nvim",
    event = "VeryLazy",
    config = function()
      require("focus").setup({
        autoresize = {
          width = 999, -- 旧 winwidth=999 相当: フォーカス中ウィンドウを最大化
          height = 999,
          minwidth = 20, -- 非フォーカスは幅 20 まで縮める
          minheight = 1,
        },
        -- 見た目は既存の設定に任せる (focus 独自の cursorline / signcolumn 切り替えはしない)
        ui = { cursorline = false, signcolumn = false },
      })

      -- サイドバーやフロート端末はリサイズの対象外にする
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("FocusDisable", { clear = true }),
        pattern = { "NvimTree", "toggleterm" },
        callback = function()
          vim.b.focus_disable = true
        end,
      })
    end,
  },
}
