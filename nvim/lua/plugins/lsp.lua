-- LSP: mason + mason-lspconfig v2 (旧 coc.nvim / LanguageClient / lsp.vim を置換)
-- nvim 0.11+ の vim.lsp.config / vim.lsp.enable を使用。mason-lspconfig v2 が
-- installed サーバを automatic_enable で自動 enable する。
-- mason は williamboman/ から mason-org/ に移転済み (docs/adr/0009)
return {
  { "mason-org/mason.nvim", config = true },
  {
    "mason-org/mason-lspconfig.nvim",
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
  -- conform / nvim-lint が使う外部ツールも mason で入れる。
  -- dotfiles の外にある旧ツール (volta / rbenv) に依存しないため (docs/adr/0009)
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    event = "VeryLazy",
    -- rubocop は mise の Ruby で gem としてインストールされる (docs/adr/0009, 0015)
    opts = {
      ensure_installed = { "stylua", "prettier", "eslint_d", "rubocop" },
    },
  },
}
