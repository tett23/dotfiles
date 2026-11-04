-- フォーマット / リント (旧 vim/ale.vim を conform.nvim + nvim-lint に置換)
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    opts = {
      -- 旧 ale_fix_on_save。Markdown は自動保存のたびに prettier が表全体をそろえるので、保存では整形せず、
      -- <Leader>fmt でだけ整形する (docs/adr/0082)
      format_on_save = function(bufnr)
        if vim.bo[bufnr].filetype == "markdown" then
          return nil
        end
        return { timeout_ms = 2000, lsp_format = "fallback" }
      end,
      formatters_by_ft = {
        javascript = { "prettier" },
        javascriptreact = { "prettier" }, -- JSX・TSX (docs/adr/0082)
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        markdown = { "prettier" },
        ruby = { "rubocop" },
        go = { "gofmt" },
        lua = { "stylua" }, -- lua_ls ではなく stylua で整形する (docs/adr/0045)
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")

      -- nvim-lint に textlint は同梱されていないので独自定義する
      local severities = {
        [1] = vim.diagnostic.severity.WARN,
        [2] = vim.diagnostic.severity.ERROR,
      }
      lint.linters.textlint = {
        cmd = "textlint",
        stdin = false,
        args = { "--format", "json", "--no-color" },
        stream = "stdout",
        ignore_exitcode = true,
        parser = function(output)
          local diagnostics = {}
          if output == nil or output == "" then
            return diagnostics
          end
          local ok, decoded = pcall(vim.json.decode, output)
          if not ok or type(decoded) ~= "table" then
            return diagnostics
          end
          for _, file in ipairs(decoded) do
            for _, msg in ipairs(file.messages or {}) do
              table.insert(diagnostics, {
                lnum = (msg.line or 1) - 1,
                col = (msg.column or 1) - 1,
                end_lnum = (msg.line or 1) - 1,
                end_col = msg.column or 1,
                severity = severities[msg.severity] or vim.diagnostic.severity.WARN,
                source = "textlint",
                message = msg.message,
                code = msg.ruleId,
              })
            end
          end
          return diagnostics
        end,
      }

      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        javascriptreact = { "eslint_d" }, -- JSX・TSX (docs/adr/0082)
        typescript = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        ruby = { "rubocop" },
        markdown = { "textlint" },
      }
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        group = vim.api.nvim_create_augroup("Lint", { clear = true }), -- 読み込み直しても重複しない (docs/adr/0046)
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },
}
