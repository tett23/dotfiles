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

-- ヤンクした範囲を一瞬光らせる (docs/adr/0034)
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- 前回閉じたときのカーソル位置から開く。コミットメッセージなどは毎回先頭から書くので除く (docs/adr/0034)。
-- 読み込んだ時点 (BufReadPost) ではファイルの種類がまだ決まっていないので、表示した時点 (BufWinEnter) で判定する
-- (:h last-position-jump の例と同じ)
local restore_cursor = vim.api.nvim_create_augroup("RestoreCursor", { clear = true })
vim.api.nvim_create_autocmd("BufReadPost", {
  group = restore_cursor,
  callback = function(args)
    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = restore_cursor,
      buffer = args.buf,
      once = true,
      callback = function()
        if vim.tbl_contains({ "gitcommit", "gitrebase" }, vim.bo[args.buf].filetype) then
          return
        end
        local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
        if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
          pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
      end,
    })
  end,
})

-- 独自のファイルタイプ判定 (旧 au BufRead/BufNewFile ...)
vim.filetype.add({
  filename = {
    ["Capfile"] = "ruby",
    ["Vagrantfile"] = "ruby",
  },
  extension = {
    gotmpl = "gotmpl", -- Go のテンプレート。gopls の対象のファイルタイプ (docs/adr/0039)
    thor = "ruby",
    cap = "ruby",
    erubis = "html",
    as = "actionscript",
  },
})

-- ターミナルのバッファでは、ノーマルモード (スクロールした後など) でも Ctrl-E をシェルに渡す。
-- 全体の <C-e> は winresizer が使うので、バッファごとに入力モードへ戻ってから送る (docs/adr/0073)
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("TerminalCtrlE", { clear = true }),
  callback = function(args)
    vim.keymap.set("n", "<C-e>", "i<C-e>", { buffer = args.buf, noremap = true, desc = "Ctrl-E をシェルに渡す" })
  end,
})
