# ADR 0010: 監査 (2026-10-07) の zsh / fzf 項目を、動作を壊さない範囲で是正する

- Status: Accepted
- Date: 2026-10-07
- 関連: docs/audit/2026-10-07-best-practices.md の Z1〜Z13

## Context

監査で zsh / fzf の設定に問題が見つかった。依頼は「動作を壊さないように直す。壊れる場合は
どこが壊れるかを報告する」。そこで、修正前後の対話 zsh の状態 (PATH、エイリアス、キー割り当て、
オプション、関数、環境変数、プロンプト、ウィジェット) を比較し、意図しない差分が出ないものだけを適用する。

## Decision

### 適用する

- Z1 / Z4: `zsh/zshenv` を新設し、`DOTFILES` だけを設定する。値はこのファイルの実体の場所から
  求める (固定の `~/dotfiles` をやめる)。`~/.zshenv` のリンク先を `zsh/zshenv` に直す。
  `zshrc` と `MISE_TRUSTED_CONFIG_PATHS` も `DOTFILES` を使う。
- Z6: Homebrew の PATH を手書きせず `brew shellenv` を使う。
- Z7: `extended_history` を有効にする (`share_history` と併用が推奨されている。既存の履歴も読める)。
- Z8: 補完の dump を 1 日 1 回は検査し直す (それ以外は `compinit -C` で高速に読む)。
- Z9: zinit のプラグインを現在のコミットに固定する。fast-syntax-highlighting は公式の推奨どおり
  `compinit` の後に読み込む。初回の自動 clone は新規マシンのために残す。
- Z10: プロンプトの古いバージョン分岐 (`is-at-least 4.3.7`) を外し、vcs_info を git のみにする
  (手元に svn / hg / bzr のリポジトリは無い)。stash 数の取得は git リポジトリ内だけで行う。
- Z11: 中身の無い `modern-commands.sh` と `anyenv.sh` を削除し、`langs/scala.sh` は
  ディレクトリがあるときだけ PATH に足す。
- Z12: `__gh_pr_branch` を、廃止された `hub` から `gh` に置き換える (出力の 3 列目がブランチ名で
  ある形式は保つ)。
- Z13: `which` を使った存在確認を `$+commands` にする。

### 見送る (動作が変わるため報告に留める)

- Z2: PATH などを `.zshenv` に移すと、macOS のログインシェルでは `/etc/zprofile` の
  `path_helper` が後から PATH を並べ替え、Nix / Homebrew よりシステムのコマンドが優先される。
- Z3: `XDG_RUNTIME_DIR` を外すと、`~/.local/run` を使っている Claude Code のソケット (`cc-socks`) や
  sbt の置き場所が変わる。
- Z5: 旧ツール (volta / rbenv / pyenv など) の PATH を取り除くと、nvim の rubocop がそれに頼っている
  ため使えなくなる (mise の Ruby が壊れているため)。
- Z6 の一部: `/etc/profiles/per-user` の優先順位を上げると、codex が Homebrew 版から Nix 版に変わるなど、
  使われるバイナリが変わる。
- Z7 の一部: `HISTFILE` を XDG の場所に移すと既存の履歴が読めなくなる。`hist_ignore_space` と
  `hist_reduce_blanks` は記録される内容が変わる。
- Z12 の一部: `bindkey "^,"` は端末から送れないキーだが、別のキーに割り当てるかは本人が決める。

## Consequences

- 対話シェルの見た目と挙動は変わらない (差分は比較で確認し、意図したものだけであることを報告する)。
- 非対話の zsh でも `DOTFILES` が設定されるようになる。
- 見送った項目は残るので、直すかどうかは別途決める。
