-- nvim-treesitter (main ブランチ = 書き直し版。docs/adr/0009)
-- パーサーのビルドに tree-sitter CLI が必要 (dependencies.md で Nix から導入)
local parsers = {
  "lua",
  "vim",
  "vimdoc",
  "bash",
  "ruby",
  "go",
  "javascript",
  "typescript",
  "tsx",
  "json",
  "yaml",
  "html",
  "css",
  "markdown",
  "python",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false, -- main は遅延読み込みに対応していない
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install(parsers)

      -- ハイライトとインデントは自動では有効にならないので、FileType ごとに有効化する。
      -- パーサーの無いファイルタイプでは start が失敗するので pcall で握りつぶす
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
        callback = function(args)
          if pcall(vim.treesitter.start, args.buf) then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}
