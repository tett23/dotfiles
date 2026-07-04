-- LSP: mason + mason-lspconfig v2 (旧 coc.nvim / LanguageClient / lsp.vim を置換)
-- nvim 0.11+ の vim.lsp.config / vim.lsp.enable を使用。mason-lspconfig v2 が
-- installed サーバを automatic_enable で自動 enable する。
return {
  { "williamboman/mason.nvim", config = true },
  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "neovim/nvim-lspconfig",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      -- 全サーバ共通のデフォルト設定 (cmp 連携の capabilities)
      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "ts_ls", "pyright", "gopls", "rust_analyzer", "ruby_lsp" },
        -- automatic_enable = true (デフォルト) で installed サーバを vim.lsp.enable
      })
    end,
  },
}
