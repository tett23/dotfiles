-- nvim-treesitter (旧 vim-polyglot / 手動 syntax を置換)
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- 安定版 API (main ブランチは configs モジュールを廃止済み)
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "lua", "vim", "vimdoc", "bash",
        "ruby", "go", "javascript", "typescript", "tsx",
        "json", "yaml", "html", "css", "markdown", "python",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
}
