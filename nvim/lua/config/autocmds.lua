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
