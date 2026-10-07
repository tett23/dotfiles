# ADR 0018: mise の ghc を ghcup のプラグインで入れる

- Status: Accepted
- Date: 2026-10-08

## Context

macOS の仮想マシンで `curl | sh` を素の状態から検証したところ (ADR 0017)、mise で ghc を入れられなかった。

- `mise/config.toml` の `ghc = "latest"` は、mise の既定の取得先 (`conda:ghc`、`asdf:mise-plugins/mise-ghcup`) から
  バージョンを取れず、新しいマシンでは解決できない。
- 既存のマシンで動いていたのは、以前に `ghc` という名前で入れたプラグイン (mise-plugins/mise-ghcup) が残っていたため。
- このプラグイン (asdf-ghcup) は、プラグインのディレクトリ名を扱うツール名として使う
  (`bin/list-all` の `tool=$(basename "$plugin_dir")`)。`asdf:mise-plugins/mise-ghcup` と指定すると
  名前が `asdf-mise-plugins-mise-ghcup` になり、どのツールか分からないので一覧が空になる。

## Decision

- `mise/config.toml` の `[plugins]` で、`ghc` という名前のプラグインとして
  `https://github.com/mise-plugins/mise-ghcup.git` を明示する。`[tools]` の `ghc = "latest"` はそのまま。
- `dependencies.md` にこの要件を書き、sync-deps スキルの対応表も合わせる。
- cabal は aqua (`aqua:haskell/cabal/cabal-install`) で解決できているので変えない。

## Consequences

- 新しいマシンでも mise で ghc を入れられる。
- ghc の取得には ghcup が使われる (プラグインが自前で ghcup を用意する)。
