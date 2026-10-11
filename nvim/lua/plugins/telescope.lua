-- telescope.nvim (旧 fzf / fzf.vim / unite を置換)
return {
  {
    "nvim-telescope/telescope.nvim",
    version = "*", -- 最新リリース (止まっている 0.1.x ブランチは使わない。docs/adr/0009)
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    -- . で始まるファイルも検索する。.gitignore に従い、.git の中は除く (zsh の Ctrl-P と同じ。docs/adr/0038)
    opts = {
      pickers = {
        find_files = {
          find_command = { "fd", "--type", "f", "--hidden", "--exclude", ".git", "--color", "never" },
        },
        live_grep = {
          additional_args = { "--hidden", "--glob", "!.git/" },
        },
      },
    },
  },
}
