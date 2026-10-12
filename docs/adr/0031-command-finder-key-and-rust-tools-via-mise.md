# ADR 0031: fzf のコマンド選択を Ctrl-O にし、send-to-kindle と shorten-path を mise で入れる

ステータス: 採択

## 文脈

### fzf のコマンド選択のキー (監査の Z12)

`zsh/fzf.sh` は `bindkey "^," fzf_command_finder` でコマンド選択を割り当てている。監査では「端末から送れないキー」としたが、
実際には zsh が `^,` を `,` の下位 5 ビット (`0x0C`) として解釈し、`Ctrl-L` に割り当たっている。
このため現在は `Ctrl-L` でコマンド選択が開き、本来の画面のクリア (`clear-screen`) が使えない。

### send-to-kindle と shorten-path (監査の B5)

- `bin/send-to-kindle` (Deno、[ADR 0021](0021-modernize-send-to-kindle.md), [0022](0022-send-to-kindle-env-file-option.md), [0025](0025-send-to-kindle-single-file.md)) は、独立したリポジトリ
  (https://github.com/tett23/send-to-kindle) に Rust で再実装した。macOS (aarch64・x86_64) と Linux 向けの
  ビルド済みのバイナリを GitHub のリリースで配布している。これにより、Deno 版の権限 (`-A`) の問題 (B5) も無くなる。
- `bin/short-pwd` が使う `shorten-path` は、https://github.com/tett23/shorten-path (Rust) のもの。
  削除された nightly の機能 (`box_syntax`) を使っていて今の Rust ではビルドできなかったが、そのリポジトリで直し、
  v1.0.0 としてビルド済みのバイナリをリリースした。
- どちらも現在は手で `cargo install` したもの (`~/.cargo/bin/`) で、dotfiles の依存として管理されていない。

## 実装すること

### コマンド選択のキー

- `zsh/fzf.sh` の `bindkey "^," fzf_command_finder` を `bindkey "^o" fzf_command_finder` にする。
  `Ctrl-O` は zsh の vi 挿入モードでは割り当てが無く (`self-insert`)、tmux (prefix は `Ctrl-Q`) や Ghostty ともぶつからない。
- `Ctrl-L` は zsh の既定の画面のクリア (`clear-screen`) に戻る (割り当てを外すだけで戻る)。

### send-to-kindle と shorten-path を mise で入れる

- `dependencies.md` の mise の節に、2 つのツールと入れ方を書く (`dependencies.md` が一次ソース。[ADR 0013](0013-generate-config-from-dependencies-with-claude.md))。
- `mise/config.toml` の `[tools]` に足す。

  ```toml
  [tools]
  "github:tett23/send-to-kindle" = "latest"
  "github:tett23/shorten-path" = "latest"
  ```

  - どちらも mise の `github` バックエンドで、リリースのバイナリを取得する (ビルド不要)。
  - `[tools]` の先頭 (`rust` より前) に書く。mise の `rust` は `~/.cargo/bin` を PATH に足し、mise は `[tools]` の順に
    PATH を並べる。後ろに書くと、手で `cargo install` した `~/.cargo/bin/` の同名のコマンドが優先されてしまう。
  - バージョンは他のツールと同じく固定しない (監査の N6 の方針)。

### Deno 版 send-to-kindle の削除

- `bin/send-to-kindle` を削除する。
- CI (`.github/workflows/ci.yml`) の `deno-tests` ジョブを削除する (他に Deno のテストは無い)。
- README のテストの表から send-to-kindle の行を消し、CI で実行するテストの説明を直す。
- `docs/specifications.md` の `bin/` の表から send-to-kindle を外し、mise で入れる自作のツールとして書く。CI の節も直す。
- [ADR 0021](0021-modernize-send-to-kindle.md), [0022](0022-send-to-kindle-env-file-option.md), [0025](0025-send-to-kindle-single-file.md) のステータスを「採択→0031」にする。

## 実装しないこと

- `~/.cargo/bin/` に手で入れた `send-to-kindle`・`shorten-path` の削除 (dotfiles の外のため、本人が `cargo uninstall` する)。
  `[tools]` の先頭に書くことで、残っていても mise 版が使われる。
- mise の `deno` と、VSCode の `deno.enable` の見直し (Deno は send-to-kindle 以外にも使うため)。
- `fzf_command_finder` の中身 (選べるコマンドの一覧) の変更。

## テスト設計

- 設定ファイルの変更と削除のため、自動テストは書かない。
- zsh を起動し、`bindkey -M viins '^O'` が `fzf_command_finder`、`bindkey -M viins '^L'` が `clear-screen` であることを確かめる。
- `mise install` の後、新しいシェルで `whence -a send-to-kindle shorten-path` の先頭が mise の管理下のパスで、
  `send-to-kindle --help` と `shorten-path "$(pwd)"` が動くことを確かめる。
- `bin/short-pwd` が短縮したパスを出すことを確かめる。
- 実際に `Ctrl-O` でコマンド選択が開くことは本人が確かめる。

## トレードオフ

- 2 つのツールは、リリースを作らないと更新が mise に届かない。
- `[tools]` の並び順に意味が生まれる (自作のツールは `rust` より前)。
- send-to-kindle の挙動は Rust 版の仕様に従う (設定ファイルの探し方などが Deno 版と違う場合がある)。
  仕様はそのリポジトリで管理し、dotfiles の `docs/specifications.md` には書かない。
- `Ctrl-L` でコマンド選択を開いていた場合は、`Ctrl-O` に慣れ直す必要がある。
