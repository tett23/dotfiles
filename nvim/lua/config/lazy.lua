-- lazy.nvim のブートストラップと setup
-- (lazy.nvim の公式の書き方。clone に失敗したら理由を表示して止める。docs/adr/0046)
-- clone した直後に lazy-lock.json の lazy.nvim のコミットへ切り替え、切り替えられなければ止める (docs/adr/0142)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

local function fail(msg, out)
  vim.api.nvim_echo({
    { msg .. ":\n", "ErrorMsg" },
    { out, "WarningMsg" },
    { "\n何かキーを押すと終了します..." },
  }, true, {})
  vim.fn.getchar()
  os.exit(1)
end

-- lazy-lock.json の lazy.nvim の commit を読む。読めなければ nil と理由を返す
local function locked_commit()
  local ok, lock = pcall(function()
    local path = vim.fn.stdpath("config") .. "/lazy-lock.json"
    return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  end)
  if not ok then
    return nil, tostring(lock)
  end
  local entry = lock["lazy.nvim"]
  if type(entry) ~= "table" or type(entry.commit) ~= "string" then
    return nil, "lazy-lock.json に lazy.nvim の commit がありません"
  end
  return entry.commit
end

if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    fail("lazy.nvim を clone できませんでした", out)
  end
  local commit, err = locked_commit()
  if commit then
    out = vim.fn.system({ "git", "-C", lazypath, "checkout", "-q", commit })
  end
  if not commit or vim.v.shell_error ~= 0 then
    -- 次の起動で、固定していない clone をそのまま使わないように消す
    vim.fn.delete(lazypath, "rf")
    fail("lazy.nvim を lazy-lock.json のコミットに切り替えられませんでした", commit and out or err)
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
