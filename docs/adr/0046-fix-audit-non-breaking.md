# ADR 0046: ベストプラクティスの監査 (2026-10-11) のうち、挙動を変えずに直せるものを直す

ステータス: 採択

## 文脈

ベストプラクティスの監査 (`docs/audit/2026-10-11-best-practices.md`) のうち、直しても使い勝手が変わらないものを直す。
重要度の高い Z5 (zinit の本体の固定)・N1 (CI の Nix の action)・T2 (tmux の色の変数の漏れ) もここに含める。
挙動が変わるものは [ADR 0045](0045-fix-audit-failures-and-risks.md) で扱う。

## 実装すること

### zsh・fzf

| ID | 直し方 |
|---|---|
| Z5 | `zsh/plugins.sh` で、zinit の本体を clone した後に、今使っているコミット (`d05a5301150909d8b386ebb974e1d1634740d65d`) に固定する。既に clone 済みで別のコミットなら、そのコミットに切り替える。パスは `${XDG_DATA_HOME:-$HOME/.local/share}` にそろえる |
| Z7 | `zsh/fzf.sh` の、fzf の出力を回す処理 (`__select_git_status_items`・`__git_log_oneline_*`・`__docker_*_id`) を `${(f)…}` で行ごとに回し、fzf の終了コードを返す。`__select_git_status_items` は `git status --porcelain -z` で、空白を含むパスと名前の変更に対応する |
| Z9 | `zsh/fzf.sh` の不要な `--extended`・`setopt … 2>/dev/null`・`eval "$cmd"` を消し、10 か所の `FZF_DEFAULT_OPTS="--height …"` を fzf 0.74 の `__fzf_defaults` を使う 1 つの補助関数にまとめる |
| Z11 | `zsh/common.sh` の履歴の検索のコメントを、実際の割り当て (`Alt-p` / `Alt-n`) に合わせる |
| Z13 | Z7 の解析部分 (fzf で選んだ行から値を取り出す処理) を純粋な関数に分け、`zsh/tests/` にテストを足す |

### nvim

| ID | 直し方 |
|---|---|
| V7 | `nvim/lua/config/lazy.lua` の lazy.nvim の導入の処理を、公式の現行の書き方 (`vim.uv`、clone の失敗を表示して止まる) にする |
| V8 | `nvim/lua/config/options.lua` の、使っていない `tags = "tags"` と既定と同じ `backup = false` を消す |
| V9 | 実態と合わないコメント (`keymaps.lua` のリーダーの設定場所、`nvim-tree.lua` の「常に表示」) を直す |
| V10 | `nvim/lua/plugins/lint.lua` の autocmd に augroup を付ける |
| V11 | LuaSnip に `build = "make install_jsregexp"` を付ける |

### Nix・インストール・CI

| ID | 直し方 |
|---|---|
| N1 | CI の `DeterminateSystems/nix-installer-action@main` を `DeterminateSystems/determinate-nix-action@v3` にする |
| N4 | `bootstrap.sh` の Determinate Nix のインストーラを、版を固定した URL (`https://install.determinate.systems/nix/tag/v3.23.1`) から取る |
| N5 | CI の zsh のテストを `zsh/tests/*.test.zsh` をまとめて実行する形にし、各ジョブに `timeout-minutes`、ワークフローに `concurrency` (同じブランチの古い実行を取り消す) を足す |
| N7 | `flake.nix` の不要な記述 (`darwinSystem` の `inherit system`・`home.username`・`home.homeDirectory`・`users.users.<名前>.name`) を消し、`postActivation.text` を `lib.mkBefore` にし (従来どおり home-manager の適用より先に実行する。`mkAfter` では順番が変わる)、`system.configurationRevision = self.rev or self.dirtyRev or null;` を足す |
| N8 | `.gitignore` に `result`・`result-*` を足す |
| N9 | `.githooks/pre-commit` で、adr-guard が無いときに「`mise install` を実行する」という案内を出して止まる |

### tmux

| ID | 直し方 |
|---|---|
| T2 | `tmux/statuses.conf` の色の変数を `%hidden` で定義し、環境変数に出さない |
| T3 | `tmux/tmux.conf` の `prefix + Y` を、`#{q:pane_current_path}` でパスを引用する形にする |
| T5 | `escape-time` を `10` にする (tmux 3.5 以降の既定) |
| T6 | `set -s copy-command pbcopy` を設定し、`copy-pipe-and-cancel` の `pbcopy` の指定と `tmux/scripts/copy-line` の指定を外す |
| T7 | 割り当ての無い `unbind-key -n C-a` を消す |
| T8 | 既定と同じ `bind p`・`bind n` を消す |

### Claude Code・そのほか

| ID | 直し方 |
|---|---|
| C3 | usage-hint の、テスト以外から使われていない `formatUsage` とそのテストを消す。`tsconfig.json` に、型定義は mod を読み込んだときに Claude Code が生成することをコメント (JSONC) で書く |
| C4 | `.claude/settings.json` の `enabledPlugins` から `skill-creator@claude-plugins-official` を外す (`example-skills` の中のものを使う) |
| O5 | `karabiner/karabiner.json` の使っていない空のプロファイル (`New profile`) を消す |

### ドキュメント

- `docs/specifications.md` の CI の節を直す。

## 実装しないこと

- 挙動が変わるもの ([ADR 0045](0045-fix-audit-failures-and-risks.md) と、監査の Z12・V12・G3・G4・O4)。
- 自前のパッケージ (AquaSKK・Claude デスクトップ) の CI でのビルド (監査の N2。本人の判断で CI では検査しない)。
- usage-hint のテストの CI への追加 (本人の判断で CI では検査しない)。
- Command Line Tools の更新 (N10。本人が行う)。

## テスト設計

- `zsh/tests/` のテストがすべて通ること (Z13 で足すテストは、先に書いて失敗させてから直す)。
- shellcheck が、変更したシェルスクリプト (`bootstrap.sh`・`.githooks/pre-commit`・`tmux/scripts/copy-line`) で通ること。
- `nix eval --raw .#darwinConfigurations.dione.system.drvPath` が通ること。
  変更の前後で `darwin-rebuild` の結果 (system の drvPath) が `configurationRevision` 以外で変わらないことを、
  `nix-diff` などで確かめる。
- Z5: zinit の本体のコミットが固定のコミットになること。
- Z7・Z9: fzf の代わりに決まった行を返す偽のコマンドで、各コマンドが変更の前と同じ値を返すこと (空白を含むパスでは正しい値になること)。
- nvim: ヘッドレスで起動してエラーが出ないこと、`:checkhealth` の LuaSnip の jsregexp の警告が消えること。
- tmux: 別の tmux サーバーで設定を読み込み、色の変数が `show-environment -g` に出ないこと、ステータスラインの色が変わらないこと、
  `prefix + y`・`Y` と、コピーモードの `y`・マウスでのコピーがクリップボードに入ること。
- usage-hint: `claude plugin test` と `claude plugin validate` が通ること。
- CI: push して、すべてのジョブが通ること。

## トレードオフ

- zinit の本体は、更新するときに固定のコミットを書き換える必要がある (ほかのプラグインと同じ扱い)。
- `escape-time` を 10ms にすると、vi モードで Esc を押してから次のキーまでの判定がわずかに遅くなる (体感の差はほぼ無い)。
