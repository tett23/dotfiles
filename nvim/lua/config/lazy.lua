-- lazy.nvim のブートストラップと setup
-- (lazy.nvim の公式の書き方。clone に失敗したら理由を表示して止める。docs/adr/0046)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "lazy.nvim を clone できませんでした:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\n何かキーを押すと終了します..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true, notify = false },
  -- luarocks を使うプラグインは入れていないので、luarocks 対応を無効にする (:checkhealth のエラーを消す。docs/adr/0039)
  rocks = { enabled = false },
})
