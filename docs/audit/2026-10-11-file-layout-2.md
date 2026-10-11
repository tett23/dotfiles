# dotfiles ファイル配置の監査 (2026-10-11 再実行)

[2026-10-11 のファイル配置の監査](2026-10-11-file-layout.md) の後の作業 (ADR 0041, 0042) を反映し、配置を調べ直したもの。
基準は [2026-10-09 の監査](2026-10-09-file-layout.md) と同じ (XDG Base Directory・リポジトリ内の対称性・役割の分離)。
今回は、dotfiles が作る・設定するもの (ホーム直下のディレクトリを含む) も調べた。

凡例: ✅ 対応済み / ⬜ 未対応 / ― 問題として扱わない

## 対応状況のまとめ

| 状況 | 項目 |
|---|---|
| ✅ 対応済み | L2〜L7, L9〜L16 |
| ― 問題として扱わない | L1, L8 |
| ⬜ 未対応 | L17〜L19 (今回見つかった項目) |

## 前回からの変化

- **L3・L4・L5・L6** ✅ git・tmux・zsh・rubocop の設定を XDG の場所 (`~/.config/<ツール>/`) に移した (ADR 0042)。
  ホーム直下に置く設定は `~/.zshenv` だけになった。zsh の補完のキャッシュも `~/.cache/zsh/zcompdump` に移した。
- **L13〜L16** ✅ `.vscode/settings.json` (Deno の設定) と空の `~/.tmux/` を削除し、`install.sh` の submodule の処理を消し、
  tmux のスクリプトを `tmux/scripts/` にまとめた (ADR 0041)。
- **L1・L8** ― 本人の判断で、以降は問題として扱わない。
  - L1: `.claude/CLAUDE.md`・`.claude/settings.json` が、全リポジトリ共通の設定とこのリポジトリの設定を兼ねていること。
  - L8: `bin/` を zsh の PATH の末尾に足していて、zsh 以外からは見えないこと。

## 今回見つかった項目

| ID | 区分 | 内容 | 挙動 |
|---|---|---|---|
| L17 | 残骸 | `flake.nix` が、使われていない `~/.vimbackup` を作っている | なし |
| L18 | XDG | 本人用の zsh の設定 `~/.zshrc.mine` がホーム直下 | あり |
| L19 | XDG | mise・Nix で入れたツールのデータが、ホーム直下のディレクトリに置かれている | あり |

### L17 [残骸] `~/.vimbackup`

- `flake.nix` の home-manager のアクティベーション (`createVimBackupDirectory`) が、`darwin-rebuild switch` のたびに
  `~/.vimbackup` を作る。
- nvim は `backup` と `swapfile` を無効にしていて (`nvim/lua/config/options.lua`)、`backupdir` も設定していないので、
  このディレクトリは使われていない (中身は空)。旧 vim の設定の名残と思われる。
- 案: アクティベーションを消し、`~/.vimbackup` を削除する。

### L18 [XDG] `~/.zshrc.mine`

- `zsh/zshrc` が、dotfiles の外の本人用の設定として `~/.zshrc.mine` を読む (今はファイルが無い)。
  ADR 0042 で、インストーラなどの `~/.zshrc` への追記の代わりに、ここに書くことにした。
- 案: `$ZDOTDIR` の中 (`~/.config/zsh/.zshrc.mine` など) に移す。ファイルが無いので、今は実害が無い。

### L19 [XDG] ツールのデータの置き場所

dotfiles が入れるツールのうち、次のものはデータをホーム直下に置いている。どれも環境変数で XDG の場所に移せるが、
既にあるデータの移動が要り、ツールによっては GUI のアプリなど zsh の外から使うときに環境変数が届かない。

| ディレクトリ | ツール | 移す方法 |
|---|---|---|
| `~/.cargo`・`~/.rustup` | Rust (mise) | `CARGO_HOME`・`RUSTUP_HOME` |
| `~/.ghcup`・`~/.cabal` | Haskell (mise の ghcup のプラグイン) | `GHCUP_USE_XDG_DIRS`・cabal は `~/.cabal` が無ければ XDG を使う |
| `~/.npm` | Node (mise) | `npm_config_cache` |
| `~/.bundle`・`~/.gem` | Ruby (mise) | `BUNDLE_USER_HOME`・`GEM_HOME` など |
| `~/.docker`・`~/.colima` | Docker (Nix・colima) | `DOCKER_CONFIG`・`COLIMA_HOME` |
| `~/.lesshst` | less | `LESSHISTFILE` |

- 案: 移すかどうかをツールごとに決める。`~/.cargo` は、mise の rust が PATH に足す場所でもある (ADR 0031)。
  `~/.docker`・`~/.colima` は、colima の常駐 (LaunchAgent) や GUI のアプリからも使うので、移すと影響が大きい。

## 問題が無かったもの

- ホーム直下の dotfiles のリンクは `~/.zshenv` だけ (ADR 0042)。ほかの設定は `~/.config/` の下か、macOS の決まった場所
  (`~/Library/Application Support/…`) にある。
- リポジトリ内は、ツール名・用途ごとのディレクトリに揃っている。
- `GOPATH` を `~/repositories` (ghq のルートと共有) にしているのは意図した設定 (`zsh/langs/go.sh`)。

## 参考 (dotfiles の外)

ホーム直下には、dotfiles で管理していないツール・アプリのディレクトリも多い (`.android`・`.aws`・`.cocoapods`・`.elm`・
`.DMMGamePlayer` など)。使っていないアプリの残骸が含まれていると思われるが、dotfiles の監査の対象外とする。
