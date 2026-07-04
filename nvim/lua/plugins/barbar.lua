-- バッファをタブ表示 (barbar.nvim)
return {
  {
    "romgrk/barbar.nvim",
    dependencies = {
      "lewis6991/gitsigns.nvim",      -- タブに Git 状態を表示
      "nvim-tree/nvim-web-devicons",  -- アイコン
    },
    init = function()
      vim.g.barbar_auto_setup = false
    end,
    event = "VeryLazy",
    keys = {
      { "<S-h>", "<cmd>BufferPrevious<cr>", desc = "前のバッファ" },
      { "<S-l>", "<cmd>BufferNext<cr>", desc = "次のバッファ" },
      { "<A-c>", "<cmd>BufferClose<cr>", desc = "バッファを閉じる" },
    },
    opts = {
      -- 常時表示の nvim-tree と重ならないようオフセット
      sidebar_filetypes = { NvimTree = true },
    },
    version = "^1.0.0",
  },
}
