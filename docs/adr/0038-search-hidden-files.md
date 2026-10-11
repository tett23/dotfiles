# ADR 0038: Telescope の検索と zsh の補完で、`.` で始まるファイルも対象にする

ステータス: 採択

## 文脈

`.` で始まるファイルとディレクトリ (`.github/`・`.claude/`・`.githooks/` など) を、nvim の Telescope の検索と、
zsh の `cd` の補完 (`Tab`) で見つけたい。ただし `.gitignore` で除外したものは対象にしない。

調べて分かった事情は次のとおり。

- Telescope の `find_files` (`<Leader><Leader>`・`<Leader>ff`) は、既定で fd を `fd --type f --color never` で使う。
  `.gitignore` には従うが、`.` で始まるものは対象にしない。設定 (`opts`) は空のまま。
- Telescope の `live_grep` (`<Leader>fg`) は、既定で ripgrep を使う。`.gitignore` には従うが、`.` で始まるものは検索しない。
- zsh の `Ctrl-P` (fzf のファイルの選択) は、すでに `fd --type f --hidden --follow --exclude .git` で、`.` で始まるものを
  含め、`.gitignore` に従っている (ADR 0002)。
- zsh の補完は、`.` を打たないと `.` で始まるファイルを候補に出さない。`Tab` の補完は fzf-tab で絞り込んでいる
  (ADR 0037) が、候補は zsh の補完が作る。
  - `setopt glob_dots` でも候補に出るが、これは `rm *` などのグロブ全般にも `.` で始まるものを含めてしまう。
    補完だけに効かせるには、`compinit` が用意する補完用のオプションの一覧 `_comp_options` に `globdots` を足す。
- zsh の補完は `.gitignore` を知らない。ただし `zstyle -e` で書いたスタイルは補完のたびにコードを実行して値を決めるので、
  `ignored-patterns` (候補から外すパターン) を、補完しているディレクトリで git が無視するものから作れる。

## 実装すること

### Telescope (nvim)

- `nvim/lua/plugins/telescope.lua` の `opts` に、次の設定を書く。

  ```lua
  pickers = {
    find_files = {
      -- . で始まるものも含め、.gitignore に従う。.git の中は除く (zsh の Ctrl-P と同じ)
      find_command = { "fd", "--type", "f", "--hidden", "--exclude", ".git", "--color", "never" },
    },
    live_grep = {
      additional_args = { "--hidden", "--glob", "!.git/" },
    },
  },
  ```

### zsh の補完

- `zsh/completions.sh` の `compinit` の後で、補完だけに `globdots` を効かせる。

  ```zsh
  _comp_options+=(globdots)
  ```

  - `cd` に限らず、すべての補完 (ファイル名など) で `.` で始まるものが候補に出る。
- 補完の候補から、`.git` と、git が無視するもの (`.gitignore` などで除外したもの) を外す。
  - `zsh/lib/gitignore-completion.zsh` に、ディレクトリを受け取り、その直下で git が無視するファイル・ディレクトリの名前を
    1 行に 1 つ出す関数 `__gitignored_names` を作る。
    - `git -C <ディレクトリ> ls-files --others --ignored --exclude-standard --directory` で無視されるものを列挙し、
      先頭の要素 (直下の名前) だけを重複なく出す。`--directory` で、無視されたディレクトリは中を展開せずに 1 行にする
      (`node_modules` などが大きくても速い)。
    - git のリポジトリの外では何も出さない。
  - 補完しているディレクトリは、入力中の語 (`$PREFIX`) の最後の `/` より前 (無ければカレントディレクトリ) とする。
    `~` で始まるものは展開する。
  - `zstyle -e ':completion:*' ignored-patterns` で、`.git` と `__gitignored_names` の結果を
    (グロブの特殊文字をエスケープして) パターンにする。
  - 外した候補も、ほかに候補が無いときは出る (zsh の既定の補完器 `_ignored` の動き)。`.git` と打った場合などに使える。
- `zsh/lib/gitignore-completion.zsh` は `zsh/completions.sh` から読み込む。

### ドキュメント

- `docs/specifications.md` の nvim と zsh の節に書く。

## 実装しないこと

- `setopt glob_dots` (グロブ全般の挙動を変えるため)。
- Telescope の `find_files`・`live_grep` 以外の検索 (`buffers`・`commands` など) の変更。

## テスト設計

- 設定ファイルの変更のため、自動テストは書かない。
- 一時ディレクトリに git のリポジトリを作り、`.github/ci.yml` (`.` で始まるディレクトリの中)・`.env.example`
  (`.` で始まるファイル)・`secret.txt` と `.cache/` (`.gitignore` で除外)・`.git` を置いて、次を確かめる。
  - nvim をヘッドレスで起動し、Telescope の設定の `find_command` で列挙したファイル (`fd` の出力) に
    `.github/ci.yml` と `.env.example` があり、`secret.txt`・`.cache/` の中・`.git/` の中が無いこと。
  - `live_grep` の設定の引数で `rg` を実行し、同じ結果になること。
- `zsh/tests/gitignore-completion.test.zsh` で `__gitignored_names` をテストし (先にテストを書く)、CI の zsh のテストに足す。
  - 一時ディレクトリの git のリポジトリで、`.gitignore` で除外したファイル・ディレクトリ (`.cache/`・`secret.txt`・`node_modules/`) の
    名前を出し、除外していないもの (`.github`・`.env.example`・`src`) と追跡済みのファイルは出さないこと。
  - サブディレクトリを渡したときは、その直下の名前を出すこと (ネストした `.gitignore` も効くこと)。
  - git のリポジトリの外では何も出さないこと。
- zsh で、`_comp_options` に `globdots` が入り、`zstyle -L` に `ignored-patterns` の設定があることを確かめる。
- tmux の中で zsh を起動し、上の一時リポジトリで `ls ` の後に `Tab` を押したときの候補を、fzf-tab を一時的に無効にして
  (候補をそのまま画面に出して) 確かめる。`.github`・`.env.example` が出て、`.git`・`.cache`・`secret.txt` が出ないこと。
- 実際に `cd <Tab>` で `.github` などが候補に出て `.git` が出ないこと、Telescope の検索で `.` で始まるファイルが
  見つかることは本人が確かめる。

## トレードオフ

- 補完のたびに git を実行する (git のリポジトリの中だけ)。非常に大きなリポジトリでは `Tab` が遅くなることがある。
- 独自の補完の仕組み (関数とスタイル) が増える。
- すべての補完で `.` で始まるものが候補に出るため、ホームディレクトリなどでは候補が増える。
- Telescope の検索で、`.` で始まる設定ファイル (`.env` など、`.gitignore` していないもの) も見つかるようになる。
