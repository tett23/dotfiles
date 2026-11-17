# ADR 0136: mise の npm のツールの lock (mise/.mise/locks) をコミットする

Status: proposed

## 文脈

[ADR 0134](0134-mise-lockfile-checksums.md) は、mise のロックファイル `mise/mise.lock` を置き、入れたツールのハッシュを確かめると決めた。
そのとき、使い捨てのディレクトリでの調査から、npm のツール (`prh`、`typescript`) はロックファイルで守れないと結論した。
`mise.lock` の `aube` の `digest` を書き換えても mise はそのまま入れ、`aube` の `path` のディレクトリは作られなかったためである。

ところが、[ADR 0134](0134-mise-lockfile-checksums.md) を実装して本物の設定で `mise lock` を動かすと、`mise/.mise/locks/<ツール>/<版>/` に、npm のツールごとの `aube-lock.yaml` と `package.json` ができた。
この ADR では、この二つのファイルを「npm の lock」と呼ぶ。
`mise/mise.lock` の `aube` の `path` は、npm の lock のディレクトリを指している。
npm の lock は、今はコミットしていない。
そのため、この ADR で、npm の lock が npm のツールを守るかを調べ直し、扱いを決める。

## 調査した事項

`mise 2026.10.17` で、`$TMPDIR` の使い捨てのディレクトリに `"npm:prh" = "latest"` だけの設定を置き、`MISE_CONFIG_DIR`、`MISE_GLOBAL_CONFIG_FILE`、`MISE_DATA_DIR`、`MISE_CACHE_DIR`、`MISE_STATE_DIR` をそこに向けて確かめた。
入れ直すときは、毎回、`MISE_DATA_DIR`、`MISE_CACHE_DIR`、`MISE_STATE_DIR` を消し、設定のディレクトリを `mise lock` の直後の写しに戻した。

- `mise lock -g --platform macos-arm64` は、`mise.lock` の隣に `.mise/locks/npm-prh/7.0.0/` を作り、npm の lock を書いた。`mise.lock` には `aube = { path = ".mise/locks/npm-prh/7.0.0", digest = "sha256:…" }` を書いた。
- `aube-lock.yaml` は、`lockfileVersion: '9.0'` の形で、`prh@7.0.0` と、その依存 (`argparse@3.0.4`、`commander@15.1.0`、`diff@9.0.0`、`js-yaml@5.5.0`) のそれぞれに `integrity: sha512-…` を持つ。
- 何も変えずに `mise install` を動かすと、`npm:prh@7.0.0` を入れた。
- `aube-lock.yaml` の `prh@7.0.0` の `integrity` を、形の正しい別のハッシュ (`argparse` のもの) に書き換えると、`mise install` は `integrity verification failed: integrity mismatch` で失敗し、何も入れなかった。
- `aube-lock.yaml` の依存の `argparse@3.0.4` の `integrity` を書き換えても、同じく `integrity mismatch` (`chain: prh@7.0.0 > js-yaml@5.5.0 > argparse@3.0.4`) で失敗し、何も入れなかった。
- `mise.lock` の `aube` の `digest` だけを書き換えると、`mise install` は止まらずに入れ、`digest` を正しい値に書き直した。
- `.mise/` を消し、`mise.lock` だけを残して `mise install` を動かすと、`dependency sidecar …/.mise/locks/npm-prh/7.0.0: No such file or directory (os error 2); run mise lock` で失敗し、何も入れなかった。
- dotfiles では、npm の lock は `mise/mise.lock` の隣、つまり dotfiles の `mise/.mise/locks/` にできた。2026-11-17 に `MISE_GLOBAL_CONFIG_FILE` を dotfiles の `mise/config.toml` に向けて `mise lock` を動かした直後の `find mise/.mise` には `npm-prh/6.1.0` があった。本人が `~/.config/mise/` のリンクを通して `bin/update-mise` を動かした後の `find mise/.mise -maxdepth 3 -type d` には、`npm-prh/7.0.0` だけがあった。
- `~/.config/mise/` には `config.toml` と `mise.lock` のリンクだけがあり、`.mise` は無い (`ls -la ~/.config/mise/`)。
- `mise/.mise/` は `.gitignore` で除かれていない (`git check-ignore -v` が何も出さない)。
- `git diff --stat -- mise/.mise` は、追跡していない `mise/.mise/` について何も出さず、`git status --short -- mise/.mise` は `?? mise/.mise/` を出す。
- `rg -c integrity` は、`npm-prh` の `aube-lock.yaml` で 5、`npm-typescript` の `aube-lock.yaml` で 21 である。
- [ADR 0134](0134-mise-lockfile-checksums.md) の調査で npm の lock のディレクトリが作られなかった理由は、確かめていない。

まとめると、mise は npm のツールを入れるとき、npm の lock の `aube-lock.yaml` の `integrity` で確かめ、合わなければ入れない。
確かめたのは、`prh` 本体と、依存の一つ (`argparse`) である。
ほかの依存と `typescript` も、`integrity` を持つので同じく確かめられると推す (確かめていない)。

また、今の master は `mise/mise.lock` だけをコミットしているので、npm の lock の無い clone での `mise install` は、npm のツールで失敗すると推す (上の `.mise/` を消した調査から推した。dotfiles の clone では確かめていない)。
`install.sh` は、`mise install --yes` が失敗しても警告を出して続ける (`install.sh` の 142〜143 行)。npm のツールの一つが失敗したときに、ほかのツール (`adr-guard` など) が入るかは、確かめていない。

## 実装すること

- `mise/.mise/locks/` をコミットする。
- `bin/update-mise` の最後の出力を、`git diff --stat -- mise/mise.lock` から `git status --short -- mise/mise.lock mise/.mise` に変える。npm の lock は、版が上がると新しい版のディレクトリが追跡していないファイルとしてできるので、`git diff` では出ないためである。ログの文 (「mise のロックファイルの変わった行数」) と、ファイルの頭の注釈も、それに合わせる。
- `docs/specifications.md` の mise のロックファイルの項を、次のとおりに直す。
  - npm のツールは、`mise/.mise/locks/` の npm の lock の `integrity` で確かめる。守れるのは、すでに npm の lock にある版のパッケージを、後から差し替えられることである。依存のパッケージも、それぞれの `integrity` で確かめる。
  - `mise install` は、`mise.lock` の `aube` の `digest` が食い違っても止まらず、書き直す。
  - 守れないものから npm のツールを外す。新しい版、ghcup で入れる ghc と cabal は、今のとおり守れない。
  - `mise install` と `bin/update-mise` が書き換えたら、`mise/mise.lock` と `mise/.mise/locks/` を一緒にコミットする。
- `docs/specifications.md` のコマンドの表の `bin/update-mise` の行の「その変わった行数を出す」を、「`mise/mise.lock` と `mise/.mise` の変わったファイルを出す」に直す。
- `.claude/skills/sync-deps/SKILL.md` の mise の項の「`mise/mise.lock` を書き換えるので、変わったらコミットする」に、`mise/.mise/locks/` を足す。
- [ADR 0134](0134-mise-lockfile-checksums.md) のステータスを、次の要素を持つ `superseded` にする。
  - `{"part":"調査した事項 (npm のツールはロックファイルで守れないという結論)","by":["docs/adr/0136-mise-npm-lock-sidecars.md"]}`
  - `{"part":"実装すること (mise/mise.lock をコミットする)","by":["docs/adr/0136-mise-npm-lock-sidecars.md"],"kind":"supplement"}`
  - `{"part":"実装すること (bin/update-mise の git diff --stat)","by":["docs/adr/0136-mise-npm-lock-sidecars.md"]}`
  - `{"part":"実装すること (docs/specifications.md の守れる範囲と守れない範囲)","by":["docs/adr/0136-mise-npm-lock-sidecars.md"]}`
  - `{"part":"実装すること (.claude/skills/sync-deps/SKILL.md の mise の項)","by":["docs/adr/0136-mise-npm-lock-sidecars.md"],"kind":"supplement"}`
  - `{"part":"実装しないこと (npm のツールを、ほかの方法で守ること)","by":[],"kind":"note","note":"ほかの方法は要らず、mise の npm の lock で守れた"}`
  - `{"part":"受けいれ条件 (A3)","by":["docs/adr/0136-mise-npm-lock-sidecars.md"]}`
  - `{"part":"トレードオフ (npm のツールは守れない)","by":["docs/adr/0136-mise-npm-lock-sidecars.md"]}`

## 実装しないこと

- `mise/.mise/` を `~/.config/mise/` にリンクすること。mise は、リンクの先の `mise/mise.lock` の隣に npm の lock を作るので、要らない。
- npm の lock を手で書き換えること。書き換えるのは `mise lock`、`mise install`、`mise upgrade` だけとする。
- 新しい版を、初めて入れる前に確かめる仕組み。[ADR 0134](0134-mise-lockfile-checksums.md) のとおり、版は `latest` のままにする。
- `go`、`node` などの言語のハッシュの確かめを調べること。

## 不変条件

なし。コミットするファイルと手順だけを決める ADR であり、判定するのは mise である。

## 受けいれ条件

- A1: `git ls-files mise/.mise` に、`mise/mise.lock` の各 `aube` の `path` の下の `aube-lock.yaml` と `package.json` がある。
- A2: `bin/update-mise` の最後に、`mise/mise.lock` と `mise/.mise` の変わったファイル (追跡していない新しいファイルを含む) が出る。
- A3: dotfiles の CI の shellcheck のジョブが通る。

この ADR の A2 は、[ADR 0134](0134-mise-lockfile-checksums.md) の A3 を置き換える。

## テスト設計

設定とファイルの変更なので、自動のテストは書かない。実装の後に次を確かめる。

- A1: `rg -o 'path = "[^"]*"' mise/mise.lock` の各パスの頭に `mise/` を付け、そのパスの下の二つのファイルが `git ls-files` に出ることを確かめる。
- A2: 本人が `bin/update-mise` を動かしたときの出力で確かめる。
- A3: CI の結果で確かめる。

## トレードオフ

- `bin/update-mise` のたびに、npm の lock の版のディレクトリが入れ替わり、コミットの差分が増える。
- 新しい版は、初めて入れたときの `integrity` を信じる。侵された版が新しい版として出たときは、防げない。

## 参考文献

- dotfiles の [ADR 0134](0134-mise-lockfile-checksums.md)
- mise の `mise lock --help`、`mise install --help`
