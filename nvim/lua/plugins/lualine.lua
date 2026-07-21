-- lualine.nvim (旧 lightline / lightline-ale を置換)

-- バッファ全体の文字数 (書記素単位: 合成文字・濁点結合などは1文字と数える)。
-- 全行走査は重いので changedtick が変わったときだけ再計算する
local char_count_cache = { buf = -1, tick = -1, count = 0 }
local function buffer_char_count()
  local buf = vim.api.nvim_get_current_buf()
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  if char_count_cache.buf ~= buf or char_count_cache.tick ~= tick then
    local count = 0
    for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, true)) do
      count = count + vim.fn.strcharlen(line)
    end
    char_count_cache = { buf = buf, tick = tick, count = count }
  end
  return char_count_cache.count .. "字"
end

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        icons_enabled = true,
        theme = "auto",
        section_separators = "",
        component_separators = "",
      },
      sections = {
        lualine_c = { { "filename", path = 1 } },
        lualine_x = {
          -- カーソル位置の文字コード (旧 statusline の code:%B 相当)
          function()
            local ch = vim.fn.strcharpart(vim.fn.strpart(vim.fn.getline("."), vim.fn.col(".") - 1), 0, 1)
            if ch == "" then
              return ""
            end
            return string.format("U+%04X", vim.fn.char2nr(ch))
          end,
          "diagnostics",
          "encoding",
          "filetype",
        },
        -- 右端: 行:列の右に文字数 (書記素単位)
        lualine_z = { "location", buffer_char_count },
      },
    },
  },
}
