# ADR 0056: 古い ghcup と stack を消し、VSCode の Haskell 拡張が mise の ghcup を使うようにする

ステータス: 採択

## 文脈

[ADR 0055](0055-improvements-2026-10-13.md) で ghcup の使っていない版を消したときに、次のことが分かった。

- `~/.ghcup/bin/ghcup` は 2024 年に入れた古い版 (0.1.30.0。108MB) のまま残っている。今の ghcup は mise で入れていて
  (0.2.6.2。[ADR 0050](0050-ghc-cabal-via-ghcup.md))、古い版は新しい ghcup が作ったリンク (`~/.ghcup/bin/cabal` など) を読めず、
  `ghcup rm` などがエラーで止まる。zsh では mise の版が PATH で先に見つかるので、普段は使われない。
- ghcup で入れた stack が 4 版ある (2.9.1・2.9.3・2.15.5・2.15.7。合わせて約 500MB。既定は 2.15.5)。stack のデータ (`~/.stack`) は 6.0GB で、
  stack が自分で入れた ghc (9.0.2・9.2.4。4.2GB) と、パッケージのキャッシュ (1.5GB) が大半。
  `~/repositories/src` に stack を使うプロジェクト (`stack.yaml`) は無く、dotfiles も stack を入れていない (`dependencies.md` に無い)。
- VSCode の Haskell 拡張 (haskell.haskell 2.8.2) は `haskell.manageHLS: "GHCup"` で、ghcup を次の順に探す
  (拡張の `dist/extension.js` で確かめた)。
  1. `haskell.ghcupExecutablePath` の設定 (`${HOME}` などを置き換える)
  2. PATH の `ghcup`
  3. `~/.ghcup/bin/ghcup`

  Dock などから起動した VSCode の PATH には mise が入らないので、今は 3 の古い ghcup を使っているとみられる。
  古い ghcup を消すと、拡張は ghcup を見つけられなくなる。
- 拡張は、起動時に `ghcup upgrade` を実行する (`haskell.upgradeGHCup`。既定は有効)。`ghcup upgrade` は新しい ghcup を `~/.ghcup/bin/ghcup` に置くので、
  古い ghcup の場所に、mise とは別の ghcup がまた作られる。
- 拡張は、`haskell.toolchain` の `stack` の値を ghcup に渡して stack を入れる。今の値は `"recommend"` (`vscode/settings.json`)。
  値を `null` にすると stack を入れない (拡張は値が null のとき `--stack` を渡さない)。

## 実装すること

### dotfiles の設定

- `vscode/settings.json` を次のようにする。
  - `haskell.ghcupExecutablePath` を `${HOME}/.local/share/mise/installs/ghcup/latest/ghcup` にする (mise の ghcup を使う)。
  - `haskell.upgradeGHCup` を `false` にする (ghcup の更新は mise で行う。`bin/update-mise`)。
  - `haskell.toolchain` の `stack` を `null` にする (stack を入れない)。
- `docs/specifications.md` に、VSCode の Haskell 拡張は mise の ghcup を使い、stack は入れないことを書く。

### dotfiles の外の片付け (この端末)

- `ghcup rm stack <版>` で、stack の 4 版をすべて消す (mise の ghcup を使う)。
- `~/.stack` を消す (約 6.0GB)。
- `~/.ghcup/bin/ghcup` (古い ghcup) を消す。

## 実装しないこと

- ghcup の cache (`~/.ghcup/cache`。385MB) の削除 (ghcup の再インストールで使われる。この ADR とは別)。
- `haskell.toolchain` のほかの値 (`ghc`・`hls` などの `"recommend"`) の見直し。
- ほかの端末の片付け (必要になった端末で同じ手順を行う)。

## テスト設計

- 設定とファイルの削除のため、自動テストは書かない。
- `vscode/settings.json` が JSONC として読めること (コメントを除いて JSON として読む)。3 つの設定が上のとおりであること。
- `ghcup list -c installed` に stack が無く、`~/.stack` と `~/.ghcup/bin/ghcup` が無いこと。
- 新しい zsh で `ghcup` が mise の版 (0.2.6.2 以降) を指し、`ghc`・`cabal` の版が変わらない (9.14.1・3.18.1.0) こと。
- `${HOME}/.local/share/mise/installs/ghcup/latest/ghcup` が実行できること。
- 本人が VSCode で Haskell のファイルを開き、HLS が起動すること (拡張の出力に、mise の ghcup の場所が出ること)。

## トレードオフ

- stack を使うプロジェクトを扱うときは、stack を入れ直す必要がある (`ghcup install stack`。`~/.stack` の ghc やパッケージもダウンロードし直す)。
- VSCode の設定に mise の内部のパス (`installs/ghcup/latest`) を書くので、mise がこの置き場所を変えると拡張が ghcup を見つけられなくなる。
- 拡張が ghcup を自動で更新しなくなる。ghcup は mise の `latest` で、`bin/update-mise` のときに更新される。
