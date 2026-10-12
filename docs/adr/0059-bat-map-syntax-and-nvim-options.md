# ADR 0059: bat の言語の割り当てと、nvim の scrolloff・signcolumn・inccommand

ステータス: 採択

## 文脈

[dotfiles の改善案 (2026-10-13)](../audit/2026-10-13-improvements.md) の「提案したが入れていない便利な設定」から、本人が bat の
`--map-syntax` と、nvim の `scrolloff`・`signcolumn = "yes"`・`inccommand = "split"` を入れることにした (`splitright`・`splitbelow` は入れない)。
V12 (`<C-w>o`) は直さない。I8 (nvim 0.12.6) は、nixpkgs にまだ新しい版が来ていない。

- **bat** 0.26.1 は、拡張子とファイル名から言語を決める。dotfiles とその置き場所 (`~/.config/`) の設定ファイルで、
  色が付かない (言語を決められない) ものを調べた (`-l txt` と出力が同じものを「決められない」とした)。
  - `git/config`・`git/ignore`: `~/.config/git/` の場所では決まる (bat が `~/.config/git/config` などを知っている) が、
    dotfiles の中のファイルを直接開くと決まらない。bat には `Git Config`・`Git Ignore` の言語がある。
  - `zsh/zshrc.mine` (`~/.config/zsh/.zshrc.mine`): 決まらない。`zshrc`・`.zshrc` は bash の言語に割り当て済み。
  - `ghostty/config`: 決まらない。bat に Ghostty の言語は無い。形式 (`キー = 値`、`#` のコメント) は INI に近い。
  - `tmux/tmux.conf`: 決まらない。bat に tmux の言語は無い。コマンドを並べる形式で、シェルの書き方 (`#` のコメント、引用符) に近い。
- **nvim** の今の値は `scrolloff = 0`、`signcolumn = "auto"`、`inccommand = "nosplit"` (nvim の既定)。
  - `scrolloff`: カーソルの上下に、常に残す行数。0 では、カーソルが画面の端まで行かないと画面が動かない。
  - `signcolumn = "auto"`: 記号 (gitsigns の変更の印・診断の印) があるときだけ列を出すので、記号の出入りで本文が左右にずれる。
  - `inccommand = "nosplit"`: `:s` の置き換えの結果を、本文の中で入力しながら見せる。`"split"` にすると、画面外の行も含めた
    置き換えの一覧を下の分割に出す。

## 実装すること

- `bat/config` に次の `--map-syntax` を足す。

  | 対象 (glob) | 言語 |
  |---|---|
  | `**/git/config` | `Git Config` |
  | `**/git/ignore` | `Git Ignore` |
  | `*.zshrc.mine`・`zshrc.mine` | `Bourne Again Shell (bash)` |
  | `**/ghostty/config` | `INI` |
  | `tmux.conf`・`.tmux.conf` | `Bourne Again Shell (bash)` |

- `nvim/lua/config/options.lua` に `scrolloff = 8`、`signcolumn = "yes"`、`inccommand = "split"` を足す。
  - `scrolloff` の値は試用のうえで本人が変えることがある。値を変えるだけなら新しい ADR は作らない。
- `docs/specifications.md` の bat (zsh の節)・nvim の節に書く。

## 実装しないこと

- `splitright`・`splitbelow` (本人の判断)。
- V12 (`<C-w>o` の割り当て。本人の判断)。
- tmux・Ghostty の言語の定義 (sublime-syntax) を bat に足すこと (`bat cache --build` が要り、管理するものが増える)。
- Z8 (`fkill` のシグナル。本人が決めてから扱う)。

## テスト設計

- 設定の値の変更のため、自動テストは書かない。次を確かめる。
  - 上の表のファイル (dotfiles の中と `~/.config/` の両方) を bat で開くと、`-l txt` と違う出力になる (色が付く) こと。
    `bat --list-languages` で、それぞれの言語の対象に glob が足されていること。
  - 割り当てていないファイル (`zsh/exports.sh`・`mise/config.toml`・`flake.lock` など) の言語が変わらないこと
    (変更の前後で出力が同じ)。
  - nvim をヘッドレスで起動し、`scrolloff` が 8、`signcolumn` が `yes`、`inccommand` が `split` であること。
- 見え方は本人が確かめる。

## トレードオフ

- bat: tmux・Ghostty の設定は、本来の言語ではない (bash・INI) ので、色の付き方が一部おかしくなることがある。
  `**/git/config` は、`.git/config` (リポジトリの設定。もとから Git Config) 以外にも、`git` という名前のディレクトリの `config` すべてに効く。
- `scrolloff`: 画面の端の数行にカーソルを置けなくなる (ファイルの先頭・末尾を除く)。
- `signcolumn = "yes"`: 記号が無いときも 2 文字分の列を使う。
- `inccommand = "split"`: 置き換えを入力している間、下に分割が開く。
