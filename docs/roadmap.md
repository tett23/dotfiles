# dotfiles のロードマップ

この文書は、このリポジトリにまだ無いものを書く。
今の振る舞いは[仕様書](specifications.md)に書き、ここには書かない。
「扱う事項」の節に載る項目は、どれもまだ無い。
そのほかに、実装と自動のテストは終わったが、ADR の受けいれ条件が求める手作業 (確かめと、GitHub の設定などの操作) が残っている項目を「手で確かめる項目」にまとめる。
これらの ADR は `accepted` にしてあり、残りの手作業はこの節だけで追う。
「扱う事項」の項目は、着手するときに ADR を作る。
実装を終えたら項目を消し、振る舞いを仕様書に書く。

## 扱う事項

- **lua-lsp を有効にし直す**：Claude Code のプラグイン `lua-lsp` は、メモリをリークするので無効にしている ([ADR 0137](adr/0137-disable-lua-lsp-plugin-for-now.md))。新しい nvim がリリースされてリークが直ったら、[ADR 0137](adr/0137-disable-lua-lsp-plugin-for-now.md) を `superseded` にする新しい ADR を書き、`.claude/settings.json` の値を `true` に戻し、仕様書を直し、この項目を消す。

## 手で確かめる項目

- **Codex で prh の指摘がモデルに届くか ([ADR 0130](adr/0130-codex-prh-hook.md) の A3)**（2026-11-20 9:40 より後に確かめる）：Codex に辞書の表記 (`窓` など) を含む Markdown を書かせ、hook の出力がモデルに渡ることを本人が確かめる。Codex の利用の上限が戻るのを待つためである。確かめた結果をコミットのメッセージに書き、この項目を消す。
- **監査の記録に、auditor が何も変えなかったかの一行が入るか ([ADR 0143](adr/0143-auditor-read-only-checks.md) の A2)**（次の監査で確かめる）：次に `auditor` に監査を任せたときに、記録に、前後で作業ツリーが変わったかの一行があることを確かめる。確かめた結果をコミットのメッセージに書き、この項目を消す。
- **nvim の lazy.nvim が、固定したコミットで入るか ([ADR 0142](adr/0142-plugin-managers-fail-closed.md) の A2、A3)**：nvim の data を退かした新しい状態で起動し、`git -C ~/.local/share/nvim/lazy/lazy.nvim rev-parse HEAD` が `lazy-lock.json` のコミットであることを本人が確かめる (A2)。次に、切り替えに失敗したら止まることを確かめる (A3)。nvim の設定を `~/.config/nvim-adr0142` に写して `lazy.nvim` の `commit` を無いコミットにし、`NVIM_APPNAME=nvim-adr0142 nvim` で、理由が出て、キーを押すと終了コード 1 で終わることを確かめる。確かめた後に、`~/.config/nvim-adr0142` と `~/.local/share/nvim-adr0142` を消す。確かめた結果をコミットのメッセージに書き、この項目を消す。
- **`bin/update-nix` が適用の前に確認を取るか ([ADR 0139](adr/0139-update-nix-verify-sources.md) の A2)**：本人が実際の `bin/update-nix` を動かし、差分と確認の問いが出ること、`n` と答えると適用されないことを確かめる。確かめた結果をコミットのメッセージに書き、この項目を消す。
- **`bin/sync-deps` が、狭めた権限のままで設定を作れるか ([ADR 0140](adr/0140-sync-deps-narrow-claude-tools.md) の A2)**：本人が `dependencies.md` に一時的にパッケージを足して `bin/sync-deps` を動かし、Claude が `flake.nix` を書き換え、`nix build` が通ることを確かめる。`dontAsk` と許可の規則の書き方で生成が止まらないことも、このときに確かめる。確かめた結果をコミットのメッセージに書き、この項目を消す。
