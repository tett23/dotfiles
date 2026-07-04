-- ファイルツリー (nvim-tree.lua)
return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false, -- 常に表示するため起動時にロード
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Explorer (nvim-tree)" },
    },
    init = function()
      -- netrw を無効化 (nvim-tree 推奨)
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
    config = function()
      require("nvim-tree").setup({
        view = { width = 40 }, -- デフォルト30から10広げる
      })
      -- 起動時にファイラを自動で開き、フォーカスは編集ウィンドウに戻す
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          require("nvim-tree.api").tree.open()
          vim.cmd("wincmd p")
        end,
      })
    end,
  },
}
