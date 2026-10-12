# ADR 0053: man のページを bat で表示し、eza のエイリアスにアイコン・git の状態・ディレクトリを先に並べるオプションを付ける

ステータス: 採択

## 文脈

bat と eza は Nix で入れていて、bat はテーマの指定 (`bat/config`)、eza は短いエイリアス (`e`・`el`・`ea`・`ela`・`et`。ADR 0035) だけを
設定している。次を足す。

- `man` のページを bat で色付きにする (`MANPAGER`)。今は `PAGER=less -R` で、`man` は色の無い表示になる。
  - bat の README の推奨は `MANPAGER="sh -c 'col -bx | bat -l man -p'"`。`col -bx` で、man の太字・下線の制御文字を取り除いてから
    bat に渡す (`col` は macOS に入っている)。
- eza のエイリアスに、次のオプションを付ける。ADR 0035 では「表示のオプションを全エイリアスに付けること」を対象外にしていたが、
  本人の判断で付ける。
  - `--icons=auto`: ファイルの種類のアイコン。Ghostty には Nerd Font のアイコンが組み込まれているので、フォントの設定は要らない。
    `auto` は端末に出すときだけ付け、パイプに渡すときは付けない。
  - `--group-directories-first`: ディレクトリをファイルより先に並べる。
  - `--git`: 詳細表示 (`-l`) に git の状態の列を足す。詳細表示でしか意味が無いので、`el`・`ela` にだけ付ける。
- zsh のエイリアスは、別のエイリアスを使って定義できる (`alias el="e -l"` の `e` も展開される)。

## 実装すること

### man

- `zsh/exports.sh` で、bat があるときだけ `MANPAGER="sh -c 'col -bx | bat -l man -p'"` を設定する。

### eza

- `zsh/aliases.sh` のエイリアスを次にする。共通のオプションは `e` に持たせ、ほかは `e` から組み立てる。

  | エイリアス | 中身 |
  |---|---|
  | `e` | `eza --icons=auto --group-directories-first` |
  | `el` | `e -l --git` |
  | `ea` | `e -a` |
  | `ela` | `e -la --git` |
  | `et` | `e --tree` |

### ドキュメント

- `docs/specifications.md` の zsh の節 (エイリアス・man) を直す。
- ADR 0035 のステータスを「採択→eza の表示のオプションはADR 0053」にする。

## 実装しないこと

- bat の `--help` の表示、`--map-syntax`、`--style` の変更、bat-extras。
- eza の `--hyperlink`・`--time-style`・`et` への `--git-ignore`。
- `ls` のエイリアス (`la`・`ll` など) の変更。

## テスト設計

- シェルの設定の変更のため、自動テストは書かない。既存の zsh のテスト (`zsh/tests/`) がすべて通ること。
- 新しい zsh で次を確かめる。
  - `MANPAGER` が設定され、`man ls` を `MANPAGER` 経由で出すと色付き (bat の出力) になること (`--color=always` を足して確かめる)。
  - `alias e el ea ela et` が上の表のとおりで、`el` などが `eza -l --git --icons=auto --group-directories-first` のように展開されること
    (`el` の中の `e` が展開されること)。
  - git のリポジトリで `el` を実行すると、git の状態の列が出ること。
- 実際の見た目 (アイコン・色付きの man) は本人が確かめる。

## トレードオフ

- `man` の表示が bat になり、less の操作 (検索の `/` など) は bat の下で動く less でそのまま使える。bat が無い環境では従来どおり。
- eza の一覧にアイコンが付き、ディレクトリが先に並ぶので、従来の並び (名前順にディレクトリとファイルが混ざる) とは変わる。
- `el`・`ela` は git の状態を調べる分だけ、大きなリポジトリでは少し遅くなる。
