-- エントリポイント: lua/config 以下を読み込む

-- leader は必ずキーマップ定義より前に設定する (space)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
