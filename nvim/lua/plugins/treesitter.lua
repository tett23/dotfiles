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
  "haskell", -- .hpeg の中の Haskell の断片 (docs/adr/0100)
  "hpeg",
  "golem",
  "emet",
  "alloy",
}

-- nvim-treesitter の一覧に無い文法を、GitHub のリポジトリのサブディレクトリから入れる。
-- revision を書かず main の先頭を入れるので、:TSUpdate のたびに入れ直す。
-- queries は location からではなく、リポジトリのルートからのパスで書く (docs/adr/0100)。
-- 自分のリポジトリでない文法は、手元でビルドする C のコードを固定するため revision を書く。
-- location が無ければリポジトリのルートの文法を入れる (docs/adr/0106)
local custom_parsers = {
  hpeg = { url = "https://github.com/tett23/peg-hs", location = "editors/tree-sitter-hpeg" },
  golem = { url = "https://github.com/tett23/golem", location = "tools/editors/tree-sitter-golem" },
  emet = { url = "https://github.com/tett23/golem", location = "tools/editors/tree-sitter-emet" },
  alloy = {
    url = "https://github.com/vincentlu/tree-sitter-alloy",
    revision = "7bcc865b0d12ff4f20876efd072fd1bc11faff48",
  },
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false, -- main は遅延読み込みに対応していない
    build = ":TSUpdate",
    config = function()
      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("TreesitterCustomParsers", { clear = true }),
        pattern = "TSUpdate",
        callback = function()
          local registry = require("nvim-treesitter.parsers")
          for lang, info in pairs(custom_parsers) do
            registry[lang] = {
              install_info = {
                url = info.url,
                revision = info.revision,
                location = info.location,
                queries = info.location and (info.location .. "/queries") or "queries",
              },
            }
          end
        end,
      })
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
  -- 今いる関数・クラスの先頭行を画面上部に固定表示する (最大 3 行。docs/adr/0037)
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = { max_lines = 3 },
  },
}
