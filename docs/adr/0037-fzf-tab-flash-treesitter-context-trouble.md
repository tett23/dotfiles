# ADR 0037: fzf-tab・flash.nvim・nvim-treesitter-context・trouble.nvim を入れる

ステータス: 採択

## 文脈

有名で更新が続いている zsh と nvim のプラグインを調べ、次の 4 つを入れることにした (git 関連は CLI で操作するので対象外)。

| プラグイン                              | 用途                                               | GitHub のスター | 最終更新 |
| --------------------------------------- | -------------------------------------------------- | --------------- | -------- |
| Aloxaf/fzf-tab                          | zsh の `Tab` の補完候補を fzf で絞り込む           | 約 5.0k         | 2026-06  |
| folke/flash.nvim                        | 画面上の任意の場所に、数キーで移動する             | 約 4.3k         | 2026-08  |
| nvim-treesitter/nvim-treesitter-context | 今いる関数・クラスの先頭行を画面上部に固定表示する | 約 3.2k         | 2026-10  |
| folke/trouble.nvim                      | 診断 (エラー・警告) などを一覧で表示して移動する   | 約 6.9k         | 2025-10  |

調べて分かった事情は次のとおり。

- zsh の `Tab` には、fzf 本体 (`fzf --zsh`) の `fzf-completion` を割り当てている。これは通常の補完に、`**<Tab>` で fzf を開く機能を足したもの。
- fzf-tab は `compinit` の後、かつ zsh-autosuggestions・fast-syntax-highlighting (ウィジェットを包むプラグイン) より前に
  読み込む必要がある。この 2 つは最初のプロンプトの後に遅延読み込みしている ([ADR 0011](0011-speed-up-zsh-startup.md)) ので、`compinit` の直後に
  同期で読み込めば条件を満たす。zsh のプラグインはコミットに固定している ([ADR 0010](0010-fix-zsh-fzf-audit.md))。
- nvim の `s`・`S` は既定の 1 文字・1 行の置き換え (`cl`・`cc` と同じ) で、独自の割り当ては無い。`<Leader>x` も空いている。
- nvim のプラグインは lazy.nvim で入れ、版は `nvim/lazy-lock.json` に固定される。

## 実装すること

### fzf-tab (zsh)

- `zsh/completions.sh` の `compinit` の直後で、zinit で fzf-tab を読み込む。版は現在のコミットに固定する。

  ```zsh
  zinit ice ver"24105b15714bfec37989ed5c5b6e60f572253019"
  zinit light Aloxaf/fzf-tab
  ```

- `cd` の補完では、候補のディレクトリの中身をプレビューする (fzf-tab の README の例)。

  ```zsh
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
  ```

- `Tab` は fzf-tab の補完 (`fzf-tab-complete`) になる。`fzf-completion` の `**<Tab>` は使えなくなる。

### flash.nvim (nvim)

- `nvim/lua/plugins/editor.lua` に足し、README の推奨のキーを割り当てる。

  | キー     | モード                               | 動き                                                               |
  | -------- | ------------------------------------ | ------------------------------------------------------------------ |
  | `s`      | ノーマル・ビジュアル・オペレータ待ち | 入力した文字の位置へ移動する                                       |
  | `S`      | ノーマル・ビジュアル・オペレータ待ち | treesitter の構文の単位で範囲を選ぶ                                |
  | `r`      | オペレータ待ち                       | 離れた場所に対して操作する (例: `yr` で離れた場所をヤンクして戻る) |
  | `R`      | オペレータ待ち・ビジュアル           | treesitter の構文の単位で検索して選ぶ                              |
  | `Ctrl-S` | コマンドライン (`/` の検索中)        | 検索に flash のラベルを付けるかを切り替える                        |

- nvim の既定の `s`・`S` (置き換え) は使えなくなる。同じことは `cl`・`cc` でできる。

### nvim-treesitter-context (nvim)

- `nvim/lua/plugins/treesitter.lua` に足す。固定表示は最大 3 行にする (`max_lines = 3`)。ほかは既定のまま。

### trouble.nvim (nvim)

- `nvim/lua/plugins/lsp.lua` に足し、README の推奨のうち次のキーを割り当てる。

  | キー         | 動き                                   |
  | ------------ | -------------------------------------- |
  | `<Leader>xx` | すべての診断の一覧を開く・閉じる       |
  | `<Leader>xX` | 今のバッファの診断の一覧を開く・閉じる |
  | `<Leader>xq` | quickfix リストを開く・閉じる          |

### ドキュメント

- `docs/specifications.md` の zsh・nvim の節に、4 つのプラグインと割り当てたキーを書く。

## 実装しないこと

- fzf-tab の `cd` 以外のプレビューや見た目の設定。
- flash.nvim の `f`・`t` の拡張 (既定の有効のまま変えない) 以外の設定の変更。
- trouble.nvim の `<Leader>xx` などの 3 つ以外のキー (シンボルの一覧・LSP の参照など)。
- そのほかの候補 (zoxide・render-markdown.nvim・undotree など)。

## テスト設計

- 設定ファイルの変更のため、自動テストは書かない。既存の zsh のテスト (`zsh/tests/`) がすべて通ること。
- 新しい zsh で、`bindkey '^I'` が `fzf-tab-complete` であること、zsh-autosuggestions と fast-syntax-highlighting が
  読み込まれていることを確かめる。
- nvim をヘッドレスで起動して `Lazy! sync` (または `Lazy! install`) でプラグインを入れ、次を確かめる。
  - 3 つのプラグインが読み込めること (`require` が失敗しないこと)。
  - `s`・`S`・`<Leader>xx` などに上の割り当てがあること (`vim.fn.maparg`)。
  - `nvim/lazy-lock.json` に 3 つのプラグインのコミットが記録されること。
- 実際の使い心地 (`Tab` の補完、`cd` のプレビュー、`s` での移動、関数の先頭行の固定表示、診断の一覧) は本人が確かめる。

## トレードオフ

- zsh の `Tab` で fzf が開くようになり、従来の補完の一覧 (候補を並べて表示する形) は使えなくなる。`**<Tab>` も使えない。
- nvim の既定の `s`・`S` が使えなくなる。
- trouble.nvim は最終更新が 2025 年 10 月で、ほかより間が空いている。
- プラグインが 4 つ増え、zsh の起動時に fzf-tab を同期で読み込む分だけ起動が遅くなる。
