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
  -- 一時的な名前で clone し、lazy-lock.json のコミットに切り替えられたときだけ lazypath に移す。
  -- 途中で失敗しても lazypath には何も残らないので、次の起動で固定していない clone を使わない
  local staging = lazypath .. ".staging"
  vim.fn.delete(staging, "rf")
  local commit, err = locked_commit()
  if not commit then
    fail("lazy.nvim を lazy-lock.json のコミットに切り替えられませんでした", err)
  end
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", staging,
  })
  if vim.v.shell_error ~= 0 then
    vim.fn.delete(staging, "rf")
    fail("lazy.nvim を clone できませんでした", out)
  end
  out = vim.fn.system({ "git", "-C", staging, "checkout", "-q", commit })
  if vim.v.shell_error ~= 0 then
    vim.fn.delete(staging, "rf")
    fail("lazy.nvim を lazy-lock.json のコミットに切り替えられませんでした", out)
  end
  local ok, rename_err = vim.uv.fs_rename(staging, lazypath)
  if not ok then
    vim.fn.delete(staging, "rf")
    fail("lazy.nvim を " .. lazypath .. " に移せませんでした", tostring(rename_err))
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
