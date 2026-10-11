# ADR 0039: nvim の `:checkhealth` のエラーと警告を直す

ステータス: 採択

## 文脈

nvim の `:checkhealth` に、エラー 1 件と警告がいくつか出ている。起動時のメッセージ (`:messages`) には何も出ていない。

| 出どころ | 内容 | 原因 |
|---|---|---|
| lazy | ❌ luarocks が無い。⚠️ Lua 5.1 が無い。⚠️ luarocks を使うプラグインを入れられない | lazy.nvim の luarocks 対応 (`rocks`) が既定で有効。luarocks を使うプラグインは入れていない |
| vim.lsp | ⚠️ 不明なファイルタイプ `gotmpl` | nvim-lspconfig の gopls の設定が対象に `gotmpl` (Go のテンプレート) を含むが、nvim にこのファイルタイプが登録されていない |
| which-key | ⚠️ mini.icons が無い | which-key はキーの一覧にアイコンを出すのに mini.icons を推奨している (nvim-web-devicons は入っていて、代わりに使われている) |
| which-key | ⚠️ `gc` と `gcc` が重なっている | nvim 本体のコメントの割り当て。which-key 自身が「情報のため」としている |
| mason | ⚠️ luarocks・Composer・PHP・julia が無い | これらの言語のパッケージを入れるときに必要。そのようなパッケージは入れていない |
| vim.health | ⚠️ nvim 0.12.6 がある (今は 0.12.5) | nvim は Nix で入れていて、`flake.lock` の nixpkgs の版に従う |

## 実装すること

- lazy.nvim の luarocks 対応を無効にする (`nvim/lua/config/lazy.lua` の `setup` に `rocks = { enabled = false }`)。
- ファイルタイプ `gotmpl` を登録する (`nvim/lua/config/autocmds.lua` の `vim.filetype.add` に、拡張子 `gotmpl` を `gotmpl` として足す)。
- which-key に mini.icons (nvim-mini/mini.icons。mini.nvim のアイコンのモジュール単体) を依存として足す
  (`nvim/lua/plugins/editor.lua`)。
- `docs/specifications.md` の nvim の節に、mini.icons を足したことを書く。

## 実装しないこと

- `gc` と `gcc` の重なり (nvim 本体の割り当てで、問題ではない)。
- mason の、使っていない言語のツール (luarocks・Composer・PHP・julia) の警告 (mason の側で消す設定が無く、問題ではない)。
- nvim の 0.12.6 への更新 (Nix の更新は `bin/update-nix` で本人が行う)。

## テスト設計

- 設定ファイルの変更のため、自動テストは書かない。
- tmux の中で nvim を起動して `:checkhealth` を実行し、次を確かめる (確認用の tmux は `focus-events` と True color を
  設定して、本番の環境に合わせる)。
  - lazy の ❌ と ⚠️、vim.lsp の `gotmpl` の ⚠️、which-key の mini.icons の ⚠️ が消えること。
  - 起動時のメッセージ (`:messages`) に何も出ないこと。
- `nvim/lazy-lock.json` に mini.icons のコミットが記録されること。

## トレードオフ

- mini.icons の分だけプラグインが 1 つ増える。
- `gc` と `gcc`、mason、nvim の版の警告は残る (`:checkhealth` の警告はゼロにならない)。
