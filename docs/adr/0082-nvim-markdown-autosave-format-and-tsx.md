# ADR 0082: nvim で Markdown を保存のたびに整形しない。TSX・JSX も prettier と eslint_d の対象にする

ステータス: 採択

## 文脈

本人から、nvim の改善点を尋ねられた。設定を読み、次の 2 つが見つかった。

- Markdown の自動保存のたびに、prettier が表全体を書き換える。
  - auto-save.nvim は、挿入モードを抜けたときと、ノーマルモードで変えたときに保存する。既定 (`noautocmd = false`) では、保存のときに
    オートコマンドも動くので、conform の `format_on_save` が毎回動く。
  - conform は、Markdown を prettier で整形する (`formatters_by_ft.markdown`)。prettier は、表の列を空白でそろえる。
    [ADR 0079](0079-fix-command-audit-2026-11-04.md) で試すと、表のすべての行が書き換わった (`|---|---|` が `| --- | --- |` に、各行に列をそろえる空白が入る)。
  - コミットした ADR は、ステータスの行のほかは変えられない (adr-guard)。nvim でステータスの行を直すと、表も書き換わり、
    adr-guard にコミットを止められる。ほかのリポジトリの Markdown でも、関係の無い行が差分に入る。
- TSX・JSX のファイルが、prettier と eslint_d の対象から漏れている。
  - conform の `formatters_by_ft` と nvim-lint の `linters_by_ft` には、`javascript`・`typescript` しかない。
    `.tsx`・`.jsx` のファイルの種類は `typescriptreact`・`javascriptreact` なので、どちらにも当たらない。
  - そのため、`.tsx` は ts_ls の整形にフォールバックし (`lsp_format = "fallback"`)、`.ts` と整形の結果が違う。eslint の診断も出ない。

## 実装すること

- `nvim/lua/plugins/lint.lua` の conform の `format_on_save` を関数にし、ファイルの種類が `markdown` のときは整形しない (`nil` を返す)。
  ほかのファイルの種類は、今と同じ (`{ timeout_ms = 2000, lsp_format = "fallback" }`)。
  - `formatters_by_ft.markdown = { "prettier" }` は残す。`<Leader>fmt` を押したときだけ、Markdown を prettier で整形する。
- conform の `formatters_by_ft` に `typescriptreact`・`javascriptreact` (`prettier`) を足す。
- nvim-lint の `linters_by_ft` に `typescriptreact`・`javascriptreact` (`eslint_d`) を足す。
- `docs/specifications.md` の nvim の節に、Markdown は保存のときに整形しないこと (`<Leader>fmt` では整形すること) と、
  TSX・JSX も prettier と eslint_d の対象であることを書く。

## 実装しないこと

- auto-save.nvim の `noautocmd = true` (自動保存では整形しない)。行末の空白の削除と、保存の後の nvim-lint も動かなくなり、変わる範囲が広い。
- 自動保存をやめること。
- Markdown の整形の道具を、表をそろえないものに替えること (prettier には、表をそろえない設定が無い)。
- 保存のときの行末の空白の削除を、Markdown で止めること (末尾の空白 2 つの改行は使っていない)。
- ほかの言語 (Nix・シェル・TOML) の LSP・フォーマッター・リンター、gitsigns のキー (別の ADR で扱う)。

## テスト設計

nvim のプラグインの設定のため、CI の自動テストは書かない (CI に nvim とプラグインが無い)。実装の前に次を実行して、今の動きを確かめ (失敗を確かめ)、
実装の後にもう一度実行して確かめる。

- 作業用のディレクトリに、列のそろっていない表を含む `.md` を置き、`nvim --headless` で開いて `:w` する。ファイルが変わらないこと (`cmp`)。
- 同じファイルを開いて `<Leader>fmt` と同じ `require("conform").format({ async = false, lsp_format = "fallback" })` を実行して `:w` すると、
  表がそろうこと。
- `nvim --headless` で `.tsx`・`.jsx` のファイルを開き、`require("conform").list_formatters_to_run(0)` に `prettier` が、
  `require("lint")._resolve_linter_by_ft(vim.bo.filetype)` に `eslint_d` が入ること。
- `.ts` を保存すると、今と同じく prettier で整形されること。
- stylua で `nvim/lua/plugins/lint.lua` の書き方がそろっていること (`stylua --check`)。

## トレードオフ

- Markdown を、保存のたびには整形しなくなる。prettier で整形をそろえているリポジトリ (CI で `prettier --check` するものなど) では、
  `<Leader>fmt` を押して整形する必要がある。
- `<Leader>fmt` でコミットした ADR を整形すると、今と同じく表が書き換わる。

## 参考文献

- auto-save.nvim の README (`noautocmd`、conform との組み合わせ): https://github.com/okuuva/auto-save.nvim
- conform.nvim の `format_on_save` (関数で、バッファごとに整形しないようにできる): https://github.com/stevearc/conform.nvim
- nvim-lint の `linters_by_ft`: https://github.com/mfussenegger/nvim-lint
- prettier の Markdown の整形 (表の列をそろえる): https://prettier.io/docs/rationale
