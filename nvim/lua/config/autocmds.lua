-- オートコマンド / ファイルタイプ (vim/common.vim, vim/syntax.vim から移植)

-- 保存時に行末の空白を削除 (カーソル位置は保持)
local trim = vim.api.nvim_create_augroup("TrimTrailingWhitespace", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
  group = trim,
  pattern = "*",
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- 全角スペースをハイライトする。listchars の対象外のため、ウィンドウごとに matchadd する (docs/adr/0028)。
-- 色 (ZenkakuSpace) は plugins/colorscheme.lua で定義する
local zenkaku = vim.api.nvim_create_augroup("ZenkakuSpace", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter", "WinNew" }, {
  group = zenkaku,
  callback = function()
    if vim.w.zenkaku_space_match == nil then
      vim.w.zenkaku_space_match = vim.fn.matchadd("ZenkakuSpace", [[\%u3000]])
    end
  end,
})

-- 独自のファイルタイプ判定 (旧 au BufRead/BufNewFile ...)
vim.filetype.add({
  filename = {
    ["Capfile"] = "ruby",
    ["Vagrantfile"] = "ruby",
  },
  extension = {
    thor = "ruby",
    cap = "ruby",
    erubis = "html",
    as = "actionscript",
  },
})
