# ADR 0134: mise のロックファイルで、入れたツールのハッシュを確かめる

Status: proposed

## 文脈

mise で入れる言語とツールは、`mise/config.toml` ですべて `"latest"` にしている (`.claude/skills/sync-deps/SKILL.md` の「注意」の節、`docs/specifications.md` の mise の項)。`bin/update-mise` で最新にすることは、[ADR 0012](0012-remove-homebrew.md) で決めた。
ロックファイルもハッシュも無い。

2026-11-16 のセキュリティの監査 ([docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md) の指摘 3) は、これを重大度「中」の問題として挙げた。
`adr-guard` は Write と Edit のたびの hook と pre-commit で、`prh` は hook で動く。
そのため、リリースや npm のアカウントが侵されると、次の `mise install` か `bin/update-mise` で、その中身がそのまま動く。

本人は、版を固定しないと決めた。
版を固定すると、版を上げる仕組み (Dependabot など) が要り、運用が重くなるためである。
本人は、版を固定しないことで、サプライチェーン攻撃を防げる範囲が狭くなることを承知している。

そのため、この ADR では、`"latest"` を保ったまま、mise のロックファイルを置き、入れたことのある版のハッシュを確かめることだけを決める。

## 調査した事項

`mise 2026.10.17` で、`$TMPDIR` の使い捨てのディレクトリに設定を置き、`MISE_CONFIG_DIR`、`MISE_GLOBAL_CONFIG_FILE`、`MISE_DATA_DIR` などをそこに向けて確かめた。
設定は `"github:tett23/shorten-path" = "latest"` と `"npm:prh" = "latest"` の二つにした。
mise のロックファイルを有効にする設定 (`lockfile` など) は使っていない (`mise settings get lockfile` は「not set」)。`mise.lock` のファイルがあれば、mise はそれを読み書きした。

dotfiles の `~/.config/mise/config.toml` は、3 段のリンクである。`~/.config/mise/config.toml` から nix のストアの `home-manager-files` へ、そこから nix のストアの別のファイルへ、そこから `~/dotfiles/mise/config.toml` へつながる (精読で `ls -la ~/.config/mise` と `readlink` を動かして確かめた)。リンクは `flake.nix` の `xdg.configFile` の `"mise/config.toml".source = link "mise/config.toml";` (106 行) が作る。
そこで、設定とロックファイルを、書き込めないディレクトリ二つを通る 3 段のリンクにして確かめた。

- `mise lock -g --platform macos-arm64` は、全体の設定の隣の `mise.lock` に、版、ダウンロードの URL、`sha256` のハッシュを書いた。`mise.lock` はシンボリックリンクのまま残り、3 段の先のファイルが書き換わった。途中のディレクトリが書き込めなくても、失敗しなかった。
- `github:` のツールについて、`mise.lock` のハッシュを書き換えてから入れ直すと、mise はダウンロードしたファイルのハッシュが合わないとして、入れずにエラーで終わった。
- `npm:prh` について、`mise.lock` の `aube` の `digest` を書き換えても、mise はそのまま入れた。`aube` の `path` (`.mise/locks/npm-prh/7.0.0`) のディレクトリは作られなかった。そのため、npm のツール (`prh`、`typescript`) は、ロックファイルで守れない。
- `mise lock -g … github:tett23/shorten-path@1.0.0` で、ロックファイルの版を最新の 1.1.0 より古い 1.0.0 にしてから、入れたものの無い状態で `mise install` を動かすと、1.1.0 を入れ、ロックファイルの版とハッシュを 1.1.0 のものに書き換えた。設定が `"latest"` のとき、ロックファイルは版を止めない。
- 同じく、入れたものの無い状態での `mise install` は、3 段の先のロックファイルを書き換えた。
- `mise upgrade --help` は、ロックファイルがあれば `mise upgrade` が `mise.lock` も書き換えると書いている。
- `go`、`node`、`python` などの言語 (mise の中の取得の仕組みで入れるもの) のハッシュを確かめるかは、確かめていない。

まとめると、`"latest"` のままのロックファイルが防ぐのは、すでにロックファイルにある版のファイルを、後から差し替えられることである。
新しい版は、初めて入れたときのハッシュをそのまま信じてロックファイルに書く。

## 実装すること

- `mise lock -g --platform macos-arm64` で `mise/mise.lock` を作り、コミットする。
- `flake.nix` の `xdg.configFile` に、`config.toml` の行と並べて `"mise/mise.lock".source = link "mise/mise.lock";` を足す。`link` は、dotfiles のファイルへのリンクを作る (nix のストアに写さない) ので、mise が書き換えると dotfiles のファイルが変わる。
- `bin/update-mise` は、`mise upgrade --yes` の後に `mise lock -g --platform macos-arm64` を動かし、最後に `git -C ~/dotfiles diff --stat -- mise/mise.lock` で、ロックファイルの変わった行数を出す。`mise lock -g` を動かすのは、`mise/config.toml` に足したばかりで、まだロックファイルに無いツールの項目を、`mise upgrade` が書くかを確かめていないためである。`mise lock` は、ロックファイルにある版を、`--bump` が無ければ変えない (`mise lock --help`)。
- `mise/config.toml` の版は、今のとおり `"latest"` のままにする。
- `docs/specifications.md` の mise の項に、ロックファイルのこと、守れる範囲 (`github:` のツールの、すでに入れた版の差し替え)、守れない範囲 (新しい版、npm のツール、ghcup で入れる ghc と cabal) と、確かめていない範囲 (`go`、`node` などの言語) を書く。
- `docs/specifications.md` のリンクの表に、`~/.config/mise/mise.lock` を足す。
- `.claude/skills/sync-deps/SKILL.md` の mise の項に、`mise install` と `mise upgrade` (`bin/update-mise`) がロックファイルを書き換えるので、変わったらコミットすることを書く。
- [ADR 0012](0012-remove-homebrew.md) のステータスを、`superseded [{"part":"Decision","by":["docs/adr/0134-mise-lockfile-checksums.md"],"kind":"supplement"}]` にする。

## 実装しないこと

- 版を固定すること、版を上げる仕組み (Dependabot、Renovate など) を入れること (本人の決定)。
- `mise install --locked` (ロックファイルに URL の無いツールを入れない) を使うこと。`"latest"` では新しい版の URL がロックファイルに無いので、更新が止まる。
- npm のツールを、ほかの方法で守ること。
- `macos-arm64` のほかの環境の分をロックファイルに書くこと。`flake.nix` の `darwinConfigurations` は `dione` (Apple Silicon の Mac) の一つだけである。

## 不変条件

なし。設定の値と手順だけを決める ADR であり、判定するのは mise である。

## 受けいれ条件

- A1: `mise/mise.lock` がコミットされ、`github:` のツールの行に `checksum = "sha256:…"` がある。
- A2: 本人が `sudo darwin-rebuild switch --flake ~/dotfiles#dione` を動かした後、`~/.config/mise/mise.lock` が dotfiles の `mise/mise.lock` へのリンクになる。
- A3: `bin/update-mise` の後に、`mise/mise.lock` の変わった行数が出る。
- A4: dotfiles の CI の shellcheck のジョブが通る。

## テスト設計

設定と手順の変更なので、自動のテストは書かない。実装の後に次を確かめる。

- A1: `rg -n 'checksum = "sha256:' mise/mise.lock` で、`github:` のツールの行を数える。
- A2: 本人の switch の後に `ls -l ~/.config/mise/mise.lock` で確かめる。
- A3: 本人が `bin/update-mise` を動かしたときの出力で確かめる。
- A4: CI の結果で確かめる。

## トレードオフ

- 新しい版は、初めて入れたときのハッシュを信じる。侵されたリリースが新しい版として出たときは、防げない。
- npm のツール (`prh`、`typescript`) は守れない。
- `mise install` と `bin/update-mise` のたびに `mise/mise.lock` が変わりうるので、本人がその変更をコミットする手間が増える。

## 参考文献

- dotfiles の [ADR 0012](0012-remove-homebrew.md)
- [docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md)
- mise の `mise lock --help`、`mise upgrade --help`、`mise install --help`
- https://mise.jdx.dev/dev-tools/mise-lock.html (ロックファイルの先頭の行が指す文書。読んでいない)
