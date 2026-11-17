# dotfiles のロードマップ

この文書は、このリポジトリにまだ無いものを書く。
今の振る舞いは[仕様書](specifications.md)に書き、ここには書かない。
「扱う事項」の節に載る項目は、どれもまだ無い。
そのほかに、ADR が求める手作業の確かめが残っている項目を「手で確かめる項目」にまとめる。
どの項目も、着手するときに ADR を作る。
実装を終えたら項目を消し、振る舞いを仕様書に書く。

## 扱う事項

- **lua-lsp を有効にし直す**：Claude Code のプラグイン `lua-lsp` は、メモリをリークするので無効にしている ([ADR 0137](adr/0137-disable-lua-lsp-plugin-for-now.md))。新しい nvim がリリースされてリークが直ったら、[ADR 0137](adr/0137-disable-lua-lsp-plugin-for-now.md) を `superseded` にする新しい ADR を書き、`.claude/settings.json` の値を `true` に戻し、仕様書とこの項目を直す。

## 手で確かめる項目

- **Codex の prh のフック ([ADR 0130](adr/0130-codex-prh-hook.md) A3)**（2026-11-20 9:40 より後に確かめる）：Codex に辞書の表記 (`窓` など) を含む Markdown を書かせ、hook の出力がモデルに渡ることを本人が確かめる。Codex の利用の上限が戻るのを待つためである。確かめたら、[ADR 0130](adr/0130-codex-prh-hook.md) を `accepted` にする。
- **監査の前後の確かめの記録 ([ADR 0143](adr/0143-auditor-read-only-checks.md) A2)**（次の監査で確かめる）：次に `auditor` に監査を任せたときに、記録に、前後で作業ツリーが変わったかの一行があることを確かめる。確かめたら、[ADR 0143](adr/0143-auditor-read-only-checks.md) を `accepted` にする。
- **lazy.nvim の固定 ([ADR 0142](adr/0142-plugin-managers-fail-closed.md) A2、A3)**：nvim の data を退かした新しい状態で起動し、`git -C ~/.local/share/nvim/lazy/lazy.nvim rev-parse HEAD` が `lazy-lock.json` のコミットであることを本人が確かめる (A2)。nvim の設定を `~/.config/nvim-adr0142` に写して `lazy.nvim` の `commit` を無いコミットにし、`NVIM_APPNAME=nvim-adr0142 nvim` で、理由が出て、キーを押すと終了コード 1 で終わることを確かめる (A3)。確かめたら、[ADR 0142](adr/0142-plugin-managers-fail-closed.md) を `accepted` にする。
