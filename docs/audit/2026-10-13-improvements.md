# dotfiles の改善案 (2026-10-13)

[ベストプラクティスの監査 (2026-10-11)](2026-10-11-best-practices.md) と [ファイル配置の監査 (2026-10-11 再実行)](2026-10-11-file-layout-2.md)
の後の作業 ([ADR 0045](../adr/0045-fix-audit-failures-and-risks.md)〜[0054](../adr/0054-tmux-allow-passthrough.md)) を反映し、
残っている項目・提案したが入れていない便利な設定・その後に気づいた点を改善案としてまとめたもの。直す優先度は本人が決める。

凡例: 挙動 = 直すと使い勝手が変わるか / 手間 = 小 (数行の設定) ・中 (スクリプトやテストを伴う) ・大 (移行を伴う)

## おすすめ

効果が大きく、手間が小さいもの。

| 案 | 内容 | 挙動 | 手間 |
|---|---|---|---|
| I1 | ghcup の使っていない ghc を消す (`~/.ghcup` が 33GB) | なし | 小 |
| I2 | tmux の `extended-keys` (Shift+Enter などをペインのプログラムに渡す。Ghostty の `Cmd+P` が tmux の中の nvim に届かない件も直る見込み) | あり | 小 |
| I3 | nvim の診断を行内に出す (`virtual_text`。nvim 0.11 から既定で無効) | あり | 小 |
| I4 | `<Leader>fmt` を conform で整形する (保存時の整形と結果を揃える) | あり | 小 |
| I5 | git の便利な設定 (`commit.verbose`・`rebase.autosquash`・`branch.sort`・`column.ui`・`push.followTags`) | あり | 小 |

## 1. 前回の監査で残っている項目

[ベストプラクティスの監査 (2026-10-11)](2026-10-11-best-practices.md) のうち、[ADR 0045](../adr/0045-fix-audit-failures-and-risks.md)・[0046](../adr/0046-fix-audit-non-breaking.md)
で直していないもの。今も当てはまることを確かめた。

| 監査の ID | 内容 | 挙動 | 手間 |
|---|---|---|---|
| Z6 | `EDITOR`・`LANG`・`XDG_*` が zshrc からしか読まれず、非対話シェルに届かない (PATH 以外を zshenv に移す) | 非対話のみ | 小 |
| Z8 | fzf のプロセスの終了 (`fkill`) の既定のシグナルが SIGKILL (`-9`)。`-TERM` にする | あり | 小 |
| Z10 | fzf-tab の README が勧める `zstyle ':completion:*' menu no` とグループの見出しの設定が無い | 小 | 小 |
| Z12 | 使われていない設定 (`zsh/langs/swift.sh`・`scala.sh`、gcloud の PATH の分岐、`nolistbeep` の重複、組み込みの `where` を隠すエイリアス) | 一部あり | 小 |
| V4 | `<Leader>fmt` が conform を通らず、保存時の整形と結果が違う (I4) | あり | 小 |
| V5 | 自動保存のたびに整形と行末の空白の削除が走る (Markdown の行末 2 スペースの改行も消える) | あり | 小 |
| V6 | 診断を行内に出さない (I3) | あり | 小 |
| V12 | `<C-w>o` を `:tabnew %` にしていて、標準の `:only` が使えない | あり | 小 |
| N6 | Xcode Command Line Tools の待ち合わせが `install.sh` と `bootstrap.sh` で重複し、方式も違う | 小 | 小 |
| N10 | Command Line Tools が 14.3 (2023 年) と古い。新しいビルドで失敗することがある (本人が更新する) | なし | 小 |
| G2 | 取り込むオブジェクトの検査 (`transfer.fsckObjects`) が無い | 小 | 小 |
| G3・G4 | 同じ定義の git のエイリアス (`lg` と `lgraph`、`cl` と `cia`)、`difftool`・`mergetool` の `prompt` の不揃い | あり | 小 |
| G5 | git の便利な設定 (I5) | あり | 小 |
| T4 | `history-limit 2000000` (ペインごと) はメモリの消費が大きい | あり | 小 |
| T9 | prefix が `C-q` になった後も、既定の `C-b` の割り当てが残っている | なし | 小 |
| C1 | ステータスラインの `xargs basename` が空白を含むディレクトリ名で壊れる。jq を 4 回起動している | 小 | 小 |
| C2 | ステータスラインと usage-hint の両方がコンテキストの使用率を出している | あり | 小 |
| O2 | VSCode の Copilot の古い設定、言語 ID ではない `"md"`・`"mdx"`、保守の止まった拡張 | 小 | 小 |
| O3 | Ghostty の `Cmd+P` が tmux の中の nvim に届かない可能性 (I2 で直る見込み) | あり | 小 |
| O4 | VSCode の `<Leader> q` の割り当てが 2 つある | あり | 小 |

## 2. 提案したが入れていない便利な設定

| 分野 | 内容 | 挙動 | 手間 |
|---|---|---|---|
| tmux | `extended-keys` (I2)、`renumber-windows`、`base-index 1`、`detach-on-destroy off`、`set-titles`、ペインの大きさを繰り返しで変える割り当て (`bind -r`) | あり | 小 |
| zsh | zoxide (よく行くディレクトリに名前の一部で移動)、atuin (履歴を SQLite に保存して検索)、zsh-you-should-use (エイリアスがあるコマンドを長い形で打つと教える) | あり | 小〜中 |
| nvim | render-markdown.nvim (Markdown を整形して表示。ADR やドキュメントを書く機会が多い)、undotree (undo の履歴を木で表示。`undofile` と相性がよい)、nvim-surround / mini.surround (囲み文字の操作) | あり | 小 |
| nvim | `scrolloff`・`splitright`・`splitbelow`・`signcolumn = "yes"`・`inccommand = "split"` | あり | 小 |
| fzf | `Ctrl-R` (履歴の検索) のプレビュー、`Alt-C` の一覧を fd で作る | あり | 小 |
| bat | `--map-syntax` (拡張子で判定できないファイルの色付け)、bat-extras (`batgrep`・`batdiff`) | あり | 小 |
| eza | `et` に `--git-ignore`、`--hyperlink` | あり | 小 |

## 3. その後に気づいた点

| 案 | 内容 | 挙動 | 手間 |
|---|---|---|---|
| I1 | `~/.ghcup` が 33GB。ghc が 11 版入っていて、2022〜2024 年に入れた古い版がほとんど (使っているのは 9.14.1。[ADR 0050](../adr/0050-ghc-cabal-via-ghcup.md))。`ghcup rm ghc <版>` で消せる | なし | 小 |
| I6 | `~/.cargo/bin` に、mise で入れ直した `send-to-kindle`・`shorten-path`・`adr-guard` の古い版と、さらに古い `shorten_path` が残っている。PATH では mise が先なので使われていない (`cargo uninstall` で消せる) | なし | 小 |
| I7 | `zsh/langs/swift.sh`・`scala.sh` は、`TOOLCHAINS=swift` (Toolchains が無い) や Coursier の PATH など、今は効いていない設定 (Z12 の一部) | なし | 小 |
| I8 | nvim 0.12.6 が出ている (今は 0.12.5)。`bin/update-nix` で上がる | 小 | 小 |
| I9 | 監査レポート (`docs/audit/`) の ADR の参照はリンクになっていない (リンクの規則は `docs/specifications.md` が対象。監査レポートはコミット後に変更しないので、今後のレポートからリンクにする) | なし | 小 |
| I10 | CI の `adr` ジョブ (adr-guard) を、意図してコミット済みの ADR を書き換えるとき (リンクの追加など) に通す手段が無い。今回は失敗を受け入れた。必要なら、コミットのメッセージなどで検査を省く仕組みを adr-guard 側に足す | なし | 中 |
| I11 | `~/.nix-profile/bin` が PATH に入っている。nix-darwin の `NIX_PROFILES` に含まれる既定で、単体の home-manager は廃止済み ([ADR 0023](../adr/0023-fix-remaining-audit-items-2.md))。中身が無ければ害は無い | なし | 小 |

## 4. 扱わないと決めたもの

次は、本人の判断で見送り・保留にしたもので、この改善案の対象外。

- PATH などを `.zshenv` に移すこと (監査の Z2)、`XDG_RUNTIME_DIR` (Z3)、mise の `latest` とロックファイル (N6 (2026-10-07))。
- `.claude/` が全体用とこのリポジトリ用を兼ねること (ファイル配置の L1)、`bin/` を zsh の PATH にだけ足すこと (L8)。
- ツールのデータのホーム直下の置き場所 (L19。保留)。
- 自前のパッケージと usage-hint のテストの CI での検査 ([ADR 0046](../adr/0046-fix-audit-non-breaking.md))。
- 保存時にファイルの末尾に空行を残すこと ([ADR 0040](../adr/0040-trailing-blank-line.md)。却下)。
