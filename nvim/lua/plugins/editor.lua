-- 編集補助 (旧 auto-pairs / indent-guides / rainbow を置換・移植)
-- コメントは Neovim 標準の gc を使う (旧 caw.vim / Comment.nvim。docs/adr/0009)
return {
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },      -- 旧 jiangmiao/auto-pairs
  -- キーの一覧のアイコンに mini.icons を使う (which-key の推奨。docs/adr/0039)
  { "folke/which-key.nvim", event = "VeryLazy", dependencies = { "nvim-mini/mini.icons" }, opts = {} },
  -- 旧 vim-indent-guides。カーソルのある範囲のインデントの線を、その範囲を囲む括弧と同じ色で描く
  -- (README の rainbow-delimiters.nvim との連携。色の名前は rainbow-delimiters の既定のものを使う。docs/adr/0087)
  {
    "lukas-reineke/indent-blankline.nvim",
    dependencies = { "HiPhish/rainbow-delimiters.nvim" },
    config = function()
      require("ibl").setup({
        scope = {
          highlight = {
            "RainbowDelimiterRed",
            "RainbowDelimiterYellow",
            "RainbowDelimiterBlue",
            "RainbowDelimiterOrange",
            "RainbowDelimiterGreen",
            "RainbowDelimiterViolet",
            "RainbowDelimiterCyan",
          },
        },
      })
      local hooks = require("ibl.hooks")
      hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
    end,
  },
  -- 旧 luochen1990/rainbow。setup を呼ぶと、monokai-pro が括弧の色を当てる (docs/adr/0087)
  {
    "HiPhish/rainbow-delimiters.nvim",
    config = function()
      require("rainbow-delimiters.setup").setup({})
    end,
  },
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
