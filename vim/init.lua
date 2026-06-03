require("config.common")
require("config.keymap")
require("config.lazy")

require('lualine').setup({
  options = {
    icons_enabled = false,
    section_separators = '', component_separators = ''
  }
})

vim.cmd[[colorscheme monokai]]

local capabilities = require("cmp_nvim_lsp").default_capabilities()
require("mason").setup()

require("mason-lspconfig").setup()
require("mason-lspconfig").setup_handlers {
  function (server_name) -- default handler (optional)
    require("lspconfig")[server_name].setup {
      on_attach = on_attach, --keyバインドなどの設定を登録
      capabilities = capabilities, --cmpを連携
    }
  end,
}
