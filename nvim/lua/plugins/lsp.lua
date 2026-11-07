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
      -- Golem の LSP は mason の外 (~/.local/bin/golem)。style.toml と preflight.toml の補完のために
      -- toml も対象にし、manifest.toml の無いフォルダの TOML では起動しない (docs/adr/0092)。
      -- 関数を書く言語 Emet (.emet) も扱う (docs/adr/0100)
      vim.lsp.config("golem", {
        cmd = { "golem", "lsp" },
        filetypes = { "golem", "emet", "toml" },
        root_markers = { "manifest.toml" },
        workspace_required = true,
      })
      vim.lsp.enable("golem")
      -- peg-hs の LSP サーバーも mason の外 (mise で入れる)。.git の無いフォルダでもファイル単位で起動する。
      -- フォーマットは conform の lsp_format = "fallback" で、保存のときにこのサーバーが行う (docs/adr/0099)
      vim.lsp.config("peg_hs", {
        cmd = { "peg-hs", "lsp" },
        filetypes = { "hpeg" },
        root_markers = { ".git" },
      })
      vim.lsp.enable("peg_hs")
      -- Alloy の LSP サーバーも mason の外 (Nix の alloy6)。nvim-lspconfig の alloy_ls はコマンドが alloy なので、
      -- alloy6 に変える。diagnostics は保存したときに出る (docs/adr/0104)
      vim.lsp.config("alloy_ls", { cmd = { "alloy6", "lsp" } })
      vim.lsp.enable("alloy_ls")
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "ts_ls", "pyright", "gopls", "rust_analyzer", "ruby_lsp" },
        -- installed サーバを vim.lsp.enable する。mason-tool-installer で入れた rubocop・stylua は
        -- LSP にはしない (診断は nvim-lint、整形は conform で行う。docs/adr/0045)
        automatic_enable = { exclude = { "rubocop", "stylua" } },
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
  -- LSP の hover・定義のプレビュー・参照の一覧・コードアクションなどを、枠付きの浮動ウィンドウで出す。
  -- winbar に今いる関数などの位置を、コードアクションがある行に 💡 を出す (既定のまま。docs/adr/0097)
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    -- LSP の付いていないバッファ (nvim-lint の診断だけ) でも、:Lspsaga で読み込む (docs/adr/0098)
    cmd = "Lspsaga",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {},
  },
  -- 診断 (エラー・警告) などを一覧で表示して移動する。キーは README の推奨のうち 3 つ (docs/adr/0037)
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
    },
  },
}
