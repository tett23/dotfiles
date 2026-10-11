-- 編集補助 (旧 auto-pairs / indent-guides / rainbow を置換・移植)
-- コメントは Neovim 標準の gc を使う (旧 caw.vim / Comment.nvim。docs/adr/0009)
return {
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },      -- 旧 jiangmiao/auto-pairs
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} }, -- 旧 vim-indent-guides
  { "HiPhish/rainbow-delimiters.nvim" },                              -- 旧 luochen1990/rainbow
  -- 画面上の任意の場所に数キーで移動する。キーは README の推奨のとおり (docs/adr/0037)。
  -- 既定の s・S (置き換え) は使えなくなる (cl・cc で同じことができる)
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },
}
