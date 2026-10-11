# ADR 0050: ghc と cabal を mise ではなく ghcup で入れ、`~/.ghcup/bin` を PATH に足す

ステータス: 採択

## 文脈

Haskell の ghc と cabal は mise で入れている (`mise/config.toml`。ghc は ghcup のプラグイン `mise-ghcup` を ghc という名前で
`[plugins]` に明示する。ADR 0018)。ghcup 自体も mise で入れた (`dependencies.md`)。

ghc・cabal の版の管理を ghcup に一本化する。mise での ghc・cabal の管理はやめる。

- 今使っている版は、mise の ghc 9.14.1・cabal 3.18.2.0 (どちらも `latest`)。
- ghcup の `latest` は ghc 9.14.1・cabal 3.18.1.0 (cabal は mise より一つ古い)。ghcup の既定 (`set`) は今は ghc 9.4.8・cabal 3.16.1.0。
- ghcup で入れたツール (ghc・cabal の各版、HLS など) は `~/.ghcup/bin` に置かれるが、PATH に入っていない。
- ghcup が用意する `~/.ghcup/env` は、`~/.ghcup/bin` を PATH の先頭に入れる。
- PATH の優先順位は「mise → `~/.local/bin`・`~/bin` → home-manager → Nix 本体 → システム」で、`$DOTFILES/bin` などは末尾に足している
  (ADR 0023。`zsh/exports.sh`)。
- `install.sh` は `mise install` で ghc・cabal も入れていた。`bin/update-mise` は mise の言語・ツールを最新化する。
- VSCode の Haskell の拡張は、すでに ghcup を使う設定 (`haskell.manageHLS = GHCup`、`~/.ghcup/bin` を PATH に足す)。
- ADR 0018 は古い書き方の ADR (`- Status:`) のため、ステータスを更新しない (ADR 0032)。ADR 0018 の決定 (mise の ghcup のプラグイン) は、
  この ADR で置き換える。

## 実装すること

### mise から外す

- `mise/config.toml` から `[plugins]` の `ghc` (ghcup のプラグイン)、`[tools]` の `ghc`・`cabal` を外す。`ghcup` は残す。
- `dependencies.md` の言語の一覧から `haskell` を外し、「Haskell の ghc・cabal は mise で入れた ghcup で入れる」と書く。
- `.claude/skills/sync-deps/SKILL.md` の名前の対応表の `haskell` の行を、ghcup で入れる形に直す。
- この端末の mise で入れた ghc・cabal とプラグインを削除する (`mise uninstall ghc cabal`・`mise plugins uninstall ghc`)。

### ghcup で入れる

- この端末で、ghcup の `latest` の ghc・cabal を入れて既定にする (`ghcup install ghc latest --set`・`ghcup install cabal latest --set`)。
- `install.sh` で、`mise install` の後に同じことをする (環境変数 `DOTFILES_SKIP_HASKELL=1` で省ける。ghc は大きいため)。
- `bin/update-mise` で、mise の最新化の後に ghcup の ghc・cabal も `latest` にする (ghcup は mise で入れたツールのため、ここでまとめる)。

### PATH

- `zsh/exports.sh` で、`~/.ghcup/bin` を PATH の末尾に足す (ディレクトリがあるときだけ)。mise で ghc・cabal を入れなくなるので、
  末尾でも `ghc`・`cabal` は `~/.ghcup/bin` から使われる。
- `~/.ghcup/env` は読み込まない (PATH の先頭に入れるため)。

### ドキュメント

- `docs/specifications.md` の依存の管理の節と zsh の節 (PATH)、README のインストールの手順 (環境変数) を直す。

## 実装しないこと

- `~/.cabal/bin` の PATH への追加 (cabal の 3.10 以降は、`cabal install` したコマンドを `~/.local/bin` に置き、これは PATH に入っている)。
- ghcup で入れた古い版 (2022〜2024 年に入れたもの) の削除。
- VSCode の設定の変更。

## テスト設計

- シェルの設定の変更のため、自動テストは書かない。既存の zsh のテスト (`zsh/tests/`) がすべて通ること。shellcheck が
  `install.sh`・`bin/update-mise` で通ること。
- 新しい zsh で次を確かめる。
  - PATH の末尾のほうに `~/.ghcup/bin` があり、`ghc`・`cabal` が `~/.ghcup/bin` から使われること (mise の shim ではない)。
  - `ghc --numeric-version` が 9.14.1、`cabal --numeric-version` が 3.18.1.0 であること。
  - `haskell-language-server-wrapper` が見つかること。
- `mise ls` に ghc・cabal が無く、`mise install` が警告なく終わること。
- `install.sh` の Haskell の手順は、`DOTFILES_SKIP_HASKELL=1` で省けることを、関数を単体で呼んで確かめる (実際の新しいマシンでの確認はしない)。

## トレードオフ

- cabal が 3.18.2.0 (mise) から 3.18.1.0 (ghcup の `latest`) に一つ下がる。
- `mise install` だけでは ghc・cabal が入らない (`install.sh` か `bin/update-mise` で入る)。
- `~/.ghcup/bin` にある古い版も、名前に版を付ければ使える状態になる。
