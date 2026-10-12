# ADR 0042: git・tmux・zsh・rubocop の設定を XDG の場所 (`~/.config`) に移す

ステータス: 採択

## 文脈

ファイル配置の監査 (`docs/audit/2026-10-11-file-layout.md`) の L3〜L6 で、次の設定がホーム直下にリンクされている。
どのツールも XDG Base Directory の場所 (`~/.config/<ツール>/`) の設定を読める。リポジトリ内の場所は [ADR 0027](0027-file-layout-without-behavior-change.md) で揃えてある。

| ツール | 今のリンク先 | XDG の場所 | ツールの対応 |
|---|---|---|---|
| git | `~/.gitconfig`・`~/.gitignore_global` | `~/.config/git/config`・`~/.config/git/ignore` | git は両方を標準で読む。`~/.config/git/ignore` は `core.excludesFile` を書かなくても使われる |
| tmux | `~/.tmux.conf` | `~/.config/tmux/tmux.conf` | tmux 3.1 以降 (手元は 3.7c) は `~/.tmux.conf` が無ければ XDG の場所を読む |
| zsh | `~/.zshenv`・`~/.zshrc` | `~/.config/zsh/.zshrc` | `ZDOTDIR` を設定すると、`.zshrc` などをその場所から読む。`~/.zshenv` だけはホーム直下に必要 (`ZDOTDIR` を決める前に読むため) |
| rubocop | `~/.rubocop.yml` | `~/.config/rubocop/config.yml` | RuboCop は、プロジェクトの設定が無いときに XDG の場所の設定を読む |

調べて分かった事情は次のとおり。

- `git/config` に `excludesfile = ~/.gitignore_global` が書いてある。
- `tmux/tmux.conf` の設定の読み込み直し (`prefix + r`) が `~/.tmux.conf` を直接指している。
- zsh の補完のキャッシュ (`.zcompdump`) は `${ZDOTDIR:-$HOME}/.zcompdump` にある (`zsh/completions.sh` が古さを確かめている)。
  `ZDOTDIR` を変えると `~/.config/zsh/` に作られるが、キャッシュは設定の場所ではなく `~/.cache` に置くのが XDG に沿う。
- `zsh/zshenv` は home-manager のリンク (`mkOutOfStoreSymlink`) なので、編集はすぐに効く。`darwin-rebuild switch` で
  `~/.config/zsh/.zshrc` のリンクを張る前に `ZDOTDIR` を設定すると、新しい zsh が `.zshrc` を読めなくなる。
- home-manager は `darwin-rebuild switch` のときに、前の世代で張ったリンク (`~/.gitconfig` など) を消し、新しいリンクを張る。

## 実装すること

### リンク (`flake.nix`)

- `home.file` から `.gitconfig`・`.gitignore_global`・`.tmux.conf`・`.zshrc`・`.rubocop.yml` を外し、
  `xdg.configFile` に次を足す。`~/.zshenv` は `home.file` に残す。

  | `xdg.configFile` | リンク元 |
  |---|---|
  | `git/config` | `git/config` |
  | `git/ignore` | `git/ignore` |
  | `tmux/tmux.conf` | `tmux/tmux.conf` |
  | `zsh/.zshrc` | `zsh/zshrc` |
  | `rubocop/config.yml` | `rubocop/config.yml` |

### 各設定

- **git**: `git/config` から `excludesfile = ~/.gitignore_global` を外す (既定で `~/.config/git/ignore` が使われる)。
- **tmux**: `prefix + r` の読み込み直しを `~/.config/tmux/tmux.conf` にする。
- **zsh**:
  - `zsh/zshenv` で `ZDOTDIR=$HOME/.config/zsh` を設定する。ただし `~/.config/zsh/.zshrc` があるときだけにする
    (リンクを張る前に `ZDOTDIR` が効いて `.zshrc` が読めなくなるのを防ぐ。新しいマシンの初回のインストールでも同じ)。
  - 補完のキャッシュを `$XDG_CACHE_HOME/zsh/zcompdump` (既定は `~/.cache/zsh/zcompdump`) に置く
    (`compinit -d`。`zsh/completions.sh` の古さの確認も同じ場所を見る)。古い `~/.zcompdump` は本人が消す。
- **rubocop**: 設定の変更は無い (リンク先だけ変わる)。

### ドキュメント

- `docs/specifications.md` の設定ファイルの配置の表と、zsh の節を直す。

### 適用

- 本人が `sudo darwin-rebuild switch --flake ~/dotfiles#dione` でリンクを張り直す。

## 実装しないこと

- `bin/` の PATH (監査の L8)。
- `~/.zshrc.mine` (dotfiles の外の本人用の設定) の場所の変更。`zsh/zshrc` から今までどおり読む。
- `~/.zcompdump` など古いファイルの自動での削除。

## テスト設計

- 設定ファイルの変更のため、自動テストは書かない。既存の zsh のテスト (`zsh/tests/`) がすべて通ること。
- `nix eval --raw .#darwinConfigurations.dione.system.drvPath` が通ること (CI と同じ)。
- `darwin-rebuild switch` の後に、次を確かめる。
  - `~/.gitconfig`・`~/.gitignore_global`・`~/.tmux.conf`・`~/.zshrc`・`~/.rubocop.yml` が無く、`~/.config/` の 5 つのリンクが
    リポジトリのファイルを指していること。`~/.zshenv` は残っていること。
  - git: `git config user.name` が読め、`git check-ignore` で `git/ignore` の項目 (`.DS_Store` など) が無視されること。
  - tmux: 別の tmux サーバーを `-f` 無しで起動して、`tmux.conf` の設定 (prefix が `C-q` など) が読まれていること。
  - zsh: 新しい対話シェルで `ZDOTDIR` が `~/.config/zsh` で、`.zshrc` の設定 (エイリアス・キーの割り当て) が効いていること。
    補完のキャッシュが `~/.cache/zsh/zcompdump` に作られること。
  - rubocop: `rubocop --show-cops` などで、XDG の場所の設定が読まれること (rubocop が入っていれば)。
- リンクを張る前 (`ZDOTDIR` を設定するだけの状態) でも、新しい zsh が `~/.zshrc` を読んで動くことを確かめる。

## トレードオフ

- インストーラなどが `~/.zshrc` に追記しても、zsh は `~/.config/zsh/.zshrc` を読むので効かなくなる (新しく作られた
  `~/.zshrc` は読まれない)。追記が必要なものは `~/.zshrc.mine` に書く。
- `git/config` の `excludesfile` を外してから `darwin-rebuild switch` を実行するまでの間、本人の global ignore が効かない。
- `~/.zcompdump` が古いまま残る (本人が消す)。
