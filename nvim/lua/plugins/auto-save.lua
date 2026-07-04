-- 自動保存 (auto-save.nvim / メンテ版 okuuva fork)
return {
  {
    "okuuva/auto-save.nvim",
    version = "*",
    event = { "InsertLeave", "TextChanged" },
    opts = {},
  },
}
