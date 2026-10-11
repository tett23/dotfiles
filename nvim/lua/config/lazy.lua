-- lazy.nvim のブートストラップと setup
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true, notify = false },
  -- luarocks を使うプラグインは入れていないので、luarocks 対応を無効にする (:checkhealth のエラーを消す。docs/adr/0039)
  rocks = { enabled = false },
})
