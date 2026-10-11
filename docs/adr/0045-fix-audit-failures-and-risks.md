# ADR 0045: ベストプラクティスの監査 (2026-10-11) の故障と、挙動が変わる主なリスクを直す

ステータス: 採択

## 文脈

ベストプラクティスの監査 (`docs/audit/2026-10-11-best-practices.md`) のうち、重要度が高く、直すと挙動が変わるものを直す。
故障の 8 件は、壊れているものが直る方向の変化。挙動を変えずに直せるもの (Z5・N1・T2 を含む) は ADR 0046 で扱う。

## 実装すること

### 故障

| ID | 場所 | 直し方 |
|---|---|---|
| Z1 | `zsh/docker.sh` | `figbe` を `figrm "$1" bundle exec "${@:2}"` にし、サービス名を最初に渡す |
| Z2 | `zsh/fzf.sh` (`__yarn_workspaces`) | Yarn 4 の `yarn workspaces list --json \| jq -r .name` で一覧を作る。説明のコメントも合わせる |
| Z3 | `zsh/langs/go.sh` | `command -v go` の条件を外し、`GOPATH` と `$GOPATH/bin` の PATH を常に設定する (go が無くても害は無い) |
| V1 | `nvim/lua/config/keymaps.lua` | `:tabedit` を `<S-t>` (= `T`) から `<Leader>t` に移す。`T` は flash.nvim の文字の移動 (後方) に任せる |
| V2 | `nvim/lua/plugins/completion.lua` | nvim-cmp の読み込みを `event = { "InsertEnter", "CmdlineEnter" }` にする |
| G1 | `git/config` | `today` を `!git log --since=midnight --author="$(git config user.name)" --oneline` にする |
| T1 | `tmux/statuses.conf` | `@nova-pane` の `${pane_mode}` を `#{pane_mode}` にする |
| O1 | `tmux/scripts/lan-ip` | 既定の経路のインターフェース (`route -n get default`) の IPv4 アドレスを `ipconfig getifaddr` で出し、取れなければ `N/a` を出す数行に置き換える |

### 挙動が変わる主なリスク

| ID | 場所 | 直し方 |
|---|---|---|
| V3 | `nvim/lua/plugins/lsp.lua`・`lint.lua` | mason-lspconfig の `automatic_enable` から `rubocop` と `stylua` を外す (`automatic_enable = { exclude = { "rubocop", "stylua" } }`)。conform に `lua = { "stylua" }` を足し、Lua の整形を stylua にそろえる |
| N3 | `bin/sync-deps` | Claude に許可する `Bash(curl -fsSL https://formulae.brew.sh/:*)` を外し、`WebFetch(domain:formulae.brew.sh)` (Homebrew の API のドメインだけを読む) にする。プロンプトの取得方法の説明も合わせる |
| Z4 | `zsh/common.sh` | `setopt complete_aliases` を外し、エイリアス (`g`・`fig`・`be`・`e` など) を展開してから補完する zsh の既定に戻す |

### ドキュメント

- `docs/specifications.md` の nvim のキーの説明 (`<Leader>t`)、Lua の整形に stylua を使うことを書く。

## 実装しないこと

- 挙動を変えずに直せるもの (ADR 0046)。
- 監査の、挙動が変わる整理の項目 (Z12 の `where` のエイリアス、V12 の `<C-w>o`、G3・G4・O4)。
- `zsh/fzf.sh` の `__find_node_modules` (監査で故障ではないと確かめた)。

## テスト設計

- `zsh/tests/` のテストがすべて通ること。shellcheck が `tmux/scripts/lan-ip` で通ること。
- Z1: `figrm` を、引数を出力するだけの偽のコマンドに差し替えて `figbe web rails c` を実行し、`web bundle exec rails c` の順になること。
- Z2: 一時ディレクトリに Yarn 4 のワークスペースを 2 つ作り、一覧のコマンドが 2 つの名前を出すこと。
- Z3: `env -i` で起動した新しいログインシェルで、`GOPATH` が `~/repositories` で、PATH に `~/repositories/bin` があること。
- Z4: 新しい zsh で、`g ` の後の補完の候補に git のサブコマンドが出ること (tmux の中で zsh を起動し、fzf-tab を止めて確かめる)。
- V1・V2・V3: nvim をヘッドレスで起動し、`<Leader>t` の割り当て、`CmdlineEnter` で nvim-cmp が読み込まれること、
  有効な LSP に `rubocop`・`stylua` が無く `lua_ls`・`ruby_lsp` はあること、conform の Lua の整形が stylua であることを確かめる。
- G1: 一時的なリポジトリで今日のコミットを作り、`git today` に出ること。
- T1: 別の tmux サーバーで設定を読み込み、`@nova-pane` に `#{pane_mode}` が残ること。
- O1: `tmux/scripts/lan-ip` が IPv4 アドレスを 1 つ出すこと。
- N3: `bin/sync-deps` の許可の一覧に curl が無く、`WebFetch(domain:formulae.brew.sh)` があること (実際に Claude を動かす確認は本人が行う)。

## トレードオフ

- `T` でタブを開けなくなり、`<Leader>t` で開く。
- Ruby の rubocop の診断は nvim-lint だけになる (LSP としての rubocop のコードアクションは使えなくなる)。Lua の整形の結果が
  lua_ls から stylua に変わる。
- エイリアスの補完が、元のコマンドの補完になる (エイリアスそのものを補完の対象にしていた場合は変わる)。
- `bin/sync-deps` の Claude は、Homebrew の API を WebFetch で読む (WebFetch は内容を要約して渡すことがあり、
  url・sha256 のような値を写し取れるかを、実際に動かして確かめる必要がある)。
