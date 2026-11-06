# ADR 0094: nvim で Golem の LSP の semantic tokens を使わない

ステータス: 破棄

## 文脈

[ADR 0092](0092-nvim-golem-lsp.md) で Golem の LSP (`golem lsp`) を有効にしてから、nvim で日本語を打つと異様に遅い、と本人から報告があった。
`nvim --clean` では遅くない。

調べた結果は次のとおり (nvim 0.12.6、`~/.local/bin/golem`、Golem のマニュアル `manual/` の写しの `chapters/09-editor.gm`)。

- 今の設定の nvim を `--listen` で起動し、別の nvim から RPC で 1 文字ずつ日本語を送った (間隔 200ms、27 文字)。1 文字の処理を待つ時間の平均は 791.6ms (最大 966.1ms) だった。
- LSP の通信を記録すると、9 文字の入力のあいだに次が届いていた。
  - nvim が送る `textDocument/semanticTokens/full`: 9 回 (変更のたび)。Golem は `semanticTokensProvider` を知らせているので、nvim は変更のたびに要求する。
  - Golem が返す `window/showMessage`: 9 回。中身はどれも `LSP: no handler for: "textDocument/semanticTokens/full"` (type 1、エラー)。Golem は semantic tokens を知らせているのに、要求を処理できない。
  - Golem が送る `textDocument/publishDiagnostics`: 207 回。変更のたびに、プロジェクトのすべてのファイルの diagnostics を送り直している。
- 開いた後に、Golem のクライアントの semantic tokens を `vim.lsp.semantic_tokens.enable(false, { client_id = … })` で止めて同じように測ると、平均 4.2ms (最大 9.0ms) になった。
- 遅さは、変更のたびのエラーの知らせ (と、その表示) から来ている。publishDiagnostics の多さは、それだけでは遅くしていない (止めた後の測定でも届いているが、4.2ms で済む)。

根本の原因は Golem の側にある (処理できない機能を知らせている)。Golem を直すまで、nvim の側で semantic tokens を使わないようにする。

## 実装すること

- `nvim/lua/plugins/lsp.lua` の `vim.lsp.config("golem", …)` に `on_init` を足し、`vim.lsp.semantic_tokens.enable(false, { client_id = client.id })` で、Golem のクライアントの semantic tokens を止める。
  注釈に、この ADR と、Golem が直れば外せることを書く。
- 設定の写しで、この形を先に試した。27 文字の平均は 5.6ms (最大 10.9ms) で、通信の記録に `textDocument/semanticTokens/full` と `window/showMessage` は出なかった。
- `docs/specifications.md` の Golem の LSP の項目に、semantic tokens を使わないことを書く。

## 実装しないこと

- Golem の側の修正 (semantic tokens の要求を処理する、または知らせない。変更のたびにすべてのファイルの diagnostics を送り直さない)。Golem のリポジトリで別に扱う。
- ほかの LSP のサーバーの semantic tokens を止めること。
- `.gm` の色付け。semantic tokens が使えない今は、色付けは無いまま ([ADR 0092](0092-nvim-golem-lsp.md) と同じ)。

## テスト設計

nvim の設定の変更なので、CI の自動テストは書かない。実装の前に次を実行して遅いことを確かめ、実装の後にもう一度実行して確かめる。

- Golem のマニュアルの写しの `chapters/09-editor.gm` を、今の設定の nvim (`--headless --listen`) で開き、別の nvim から RPC で日本語を 1 文字ずつ送る (間隔 200ms、27 文字)。1 文字の処理を待つ時間の平均が、実装の前は数百 ms、実装の後は 20ms 未満になること。
- 実装の後、同じファイルを開いて、`golem` のクライアントが付き、そのクライアントで `vim.lsp.semantic_tokens.is_enabled()` が偽であること。
- 実装の後、LSP の通信の記録に `textDocument/semanticTokens/full` と `window/showMessage` が出ないこと。
- 本人が確かめる: Ghostty の nvim で `.gm` を開いて日本語を打ち、遅くないこと。diagnostics と補完は今までどおり出ること。

## トレードオフ

- Golem が semantic tokens を処理できるようになっても、この設定を外すまでは使わない。外すときは新しい ADR を書く。
- Golem の diagnostics の送り直しは残るので、プロジェクトが大きくなると、また重くなるかもしれない。

## 参考文献

- Neovim 0.12.6 の `:help vim.lsp.semantic_tokens.enable()`
