# ADR 0071: bun でグローバルに入れたコマンドを PATH に足す

ステータス: 採択

## 文脈

本人から、bun で入れた実行ファイルを PATH に足したいと要望があった。

- bun は mise で入れている (`mise/config.toml` の `bun = "latest"`。今は 1.4.3)。
- `bun add -g`・`bun install -g` で入れたコマンドの置き場所は、`bun pm bin -g` で分かる。手元では `~/.cache/.bun/bin`
  (`XDG_CACHE_HOME` を設定しているため、bun はその下の `.bun` を使う。`BUN_INSTALL` は設定していない)。
  今は `pm2` などが入っているが、PATH に無いので名前だけでは実行できない。
- PATH は `zsh/exports.sh` で設定し、ほかから足す場所 (`$DOTFILES/bin`・`~/.ghcup/bin`) は末尾に足している ([ADR 0050](0050-ghc-cabal-via-ghcup.md))。
  PATH は zshenv では変えない ([ADR 0010](0010-fix-zsh-fzf-audit.md))。
- シェルの起動のたびに `bun pm bin -g` を実行すると、起動が遅くなる ([ADR 0011](0011-speed-up-zsh-startup.md))。

## 実装すること

- `zsh/exports.sh` で、`${XDG_CACHE_HOME:-$HOME/.cache}/.bun/bin` があれば、PATH の末尾に足す (`~/.ghcup/bin` と同じ書き方)。
- `docs/specifications.md` の PATH の記述に書く。

## 実装しないこと

- `BUN_INSTALL` を設定して、置き場所をキャッシュではない場所 (`$XDG_DATA_HOME/bun` など) に移すこと (今入っているものを入れ直すことになる)。
- 起動のたびに `bun pm bin -g` で場所を求めること。
- npm・pnpm・yarn のグローバルな置き場所を PATH に足すこと。

## テスト設計

- PATH の設定の変更のため、自動テストは書かない。次を確かめる。
  - 新しい zsh で、`print -l $path` の末尾のほうに `~/.cache/.bun/bin` があり、`command -v pm2` がその下を指すこと。
  - `~/.cache/.bun/bin` が無い環境 (`XDG_CACHE_HOME` を空のディレクトリにした zsh) では、PATH に足さないこと。
  - mise・`~/.local/bin` などの、既にある PATH の順が変わらないこと。
  - 既存の zsh のテストがすべて通ること。

## トレードオフ

- 置き場所がキャッシュのディレクトリなので、キャッシュを消すと、bun で入れたコマンドも消える。
- PATH の末尾に足すので、同じ名前のコマンドが mise・Nix・システムにあれば、そちらが使われる。
- bun の版や `BUN_INSTALL` の設定で置き場所が変わると、足した PATH と合わなくなる (そのときは `bun pm bin -g` で確かめて直す)。

## 参考文献

- Bun の `bun pm bin`: https://bun.sh/docs/cli/pm
- Bun のグローバルな置き場所と `BUN_INSTALL`: https://bun.sh/docs/installation
