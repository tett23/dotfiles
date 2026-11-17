# ADR 0139: update-nix は、自前パッケージの取得元を確かめ、差分を見せて確認を取ってから適用する

Status: proposed

## 文脈

`bin/update-nix` は、`flake.lock` と `nix/pkgs/sources.json` を最新にし、ビルドして `sudo darwin-rebuild switch` で適用する ([ADR 0012](0012-remove-homebrew.md))。
`sources.json` は、nixpkgs に無い自前パッケージ (Claude デスクトップと AquaSKK) の版、URL、`sha256` を持つ。

2026-11-16 のセキュリティの監査 ([docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md) の指摘 4) は、これを重大度「低」の問題として挙げた。
`bin/update-nix` は URL と `sha256` を同じ応答 (Homebrew の公開の API) から取り、URL のホストを確かめずに `sources.json` に書き、同じ実行でビルドして root で適用する。
AquaSKK は、適用のときに root で `/Library/Input Methods` に写される。
そのため、Homebrew の応答が偽られると、その中身が root で入る。
`sha256` は、取得元と独立した確かめになっていない。
本人は、ADR を作って扱うと決めた。

そのため、この ADR で、取得元のホストを確かめ、取得元と別の経路でハッシュを確かめられるときは確かめ、適用の前に差分を見せて確認を取ると決める。

## 調査した事項

- `bin/update-nix` の `update_source` は、`curl -fsSL https://formulae.brew.sh/api/cask/<cask>.json` の応答から `version`、`url`、`sha256` を取る (41〜47 行)。`sha256` が 64 桁の 16 進であることだけを確かめ (48 行)、URL のホストは確かめない。版が変わっていれば `sources.json` を書き換える (57〜62 行)。
- `main` は、`update_flake` (`nix flake update`)、`update_sources`、`build`、`switch` の順に動かす (96〜100 行)。確認を取る場所は無く、止まるのは `sudo` のパスワードを聞かれるときだけである。`--no-switch` を付けると、ビルドで止まる (91、103 行)。
- `nix/pkgs/sources.json` の二つの URL のホストは、`claude-desktop` が `downloads.claude.ai`、`aquaskk` が `github.com` (`https://github.com/codefirst/aquaskk/releases/download/4.7.3/AquaSKK-4.7.3.pkg`) である。`nix/pkgs/*.nix` は、`fetchurl { inherit (source) url sha256; }` で取る (`aquaskk.nix` の 19 行、`claude-desktop.nix` の 16 行)。
- `flake.nix` の `system.activationScripts.postActivation` は、`rsync -a --delete` で AquaSKK を `/Library/Input Methods/AquaSKK.app/` に写す (210〜213 行)。
- Homebrew の API の cask の JSON は、`url` と `sha256` を同じ JSON の文字列として与える (`curl -s https://formulae.brew.sh/api/cask/aquaskk.json | jq '{url,sha256,version}'`)。
- GitHub のリリースの API (`https://api.github.com/repos/codefirst/aquaskk/releases?per_page=3`) は、4.7.9、4.7.8、4.7.7 の asset に `digest: "sha256:…"` を返した。`releases/latest` が返す 4.7.3 の asset の `digest` は `null` だった。古いリリースには `digest` が無い。
- Claude デスクトップの取得元 (`downloads.claude.ai`) は GitHub のリリースではないので、GitHub のリリースの API では確かめられない。
- `flake.nix` の inputs のうち、個人のリポジトリは `claude-code` (`github:sadjow/claude-code-nix`。15 行) の一つである。`nix flake update` は、すべての inputs を一度に進める (`bin/update-nix` の 35 行)。
- `bin/sync-deps` は、[ADR 0133](0133-sync-deps-confirm-before-switch.md) で、差分の全体を見せ、`SYNC_DEPS_TTY` (既定は `/dev/tty`) から読んだ答えが `y` か `yes` のときだけ適用する形にした。

## 実装すること

- `SOURCES_TO_CASKS` の要素を、`<sources.json のキー> <Homebrew の cask 名> <許す URL の接頭辞>` の空白区切りにする (接頭辞が `:` を含むため)。接頭辞は、`claude-desktop` が `https://downloads.claude.ai/`、`aquaskk` が `https://github.com/codefirst/aquaskk/releases/download/` とする。
- `main` の順を次のとおりにする。
  1. 確かめ: すべてのパッケージについて、Homebrew の応答を取り、次の二つを確かめる。この段では、どのファイルも書かない。版が今と同じでも確かめる。
     - `url` が、そのパッケージの接頭辞で始まること。始まらなければ、終了コード 1 で終わる。
     - URL が `https://github.com/<owner>/<repo>/releases/download/<tag>/<名前>` の形のときは、GitHub のリリースの API (`https://api.github.com/repos/<owner>/<repo>/releases/tags/<tag>`) から、その名前の asset の `digest` を読む。`digest` が `sha256:<Homebrew の sha256>` と違えば、終了コード 1 で終わる。`digest` が `null` なら、「GitHub のリリースにハッシュがありません。Homebrew の sha256 だけで確かめます」と出して続ける。API を読めなければ、終了コード 1 で終わる。
  2. 写し: `flake.lock` と `nix/pkgs/sources.json` を、`mktemp -d` のディレクトリに写す。
  3. 更新: `nix flake update` と、版の変わったパッケージの `sources.json` の書き換えを行う。
  4. 差分: 写しと今のファイルの差分の全体 (`git --no-pager diff --no-index`) を出す。実行の前からあった未コミットの変更は、写しに含まれるので差分に出ない。差分が無ければ、`差分はありません` と出して、ビルドも確認もせずに終了コード 0 で終わる。
  5. `build` を動かす。
  6. 適用するとき (`--no-switch` が無いとき) は、`適用しますか? [y/N]` と聞き、`UPDATE_NIX_TTY` (既定は `/dev/tty`) のファイルから 1 行を読む。読んだ行が `y` か `yes` (大文字を含む) のときだけ `switch` を呼ぶ。それ以外の答え、空の行、読めないときは、適用せずに `適用しませんでした` と出して終了コード 1 で終わる。標準入力からは読まない。理由は [ADR 0133](0133-sync-deps-confirm-before-switch.md) と同じである。
- 確認を省くオプションは置かない。
- `zsh/tests/update-nix.test.zsh` を足す。`curl`、`nix`、`sudo`、`darwin-rebuild` は、`PATH` の先頭に置いた偽のコマンドで置き換える。
- `docs/specifications.md` のコマンドの表の `bin/update-nix` の行と、`.claude/skills/sync-deps/SKILL.md` の「4. アップデート」に、確かめと確認のことを書く。
- [ADR 0012](0012-remove-homebrew.md) のステータスに、`{"part":"Decision (bin/update-nix)","by":["docs/adr/0139-update-nix-verify-sources.md"],"kind":"supplement"}` を足す。

## 実装しないこと

- `flake.lock` の inputs (とくに `sadjow/claude-code-nix`) を、個別に確かめること。差分を見せるだけにする。
- Claude デスクトップのハッシュを、Homebrew と別の経路で確かめること。別の経路が見つからない。
- `bin/sync-deps` の Claude が `nix/pkgs/sources.json` に書く URL を確かめること。その経路は、[ADR 0133](0133-sync-deps-confirm-before-switch.md) の差分の確認と、[ADR 0140](0140-sync-deps-narrow-claude-tools.md) の許すツールで扱う。
- AquaSKK を root で写す処理を変えること。
- `--no-switch` の振る舞いを変えること。ビルドで止まり、確認は取らない。

## 不変条件

- I1: どれかのパッケージの Homebrew の応答の `url` が、そのパッケージの許す接頭辞で始まらないとき、`flake.lock` と `sources.json` は変わらず、終了コードは 1 で、`nix` と `sudo` は呼ばれない。
- I2: URL が GitHub のリリースで、asset の `digest` が `sha256:<Homebrew の sha256>` と違うとき、`flake.lock` と `sources.json` は変わらず、終了コードは 1 で、`nix` と `sudo` は呼ばれない。
- I3: `--no-switch` が無く、答えが `y` か `yes` (大文字と小文字を区別しない) でなければ、`sudo` と `darwin-rebuild` は一度も呼ばれず、終了コードは 1 である。
- I4: 答えを読む前に、`flake.lock` と `sources.json` の差分の全体が標準出力に出ている。
- I5: 答えが `y` か `yes` のとき、`switch` を一度だけ呼ぶ。
- I6: asset の `digest` が `null` のとき、警告を出して続ける。
- I7: GitHub のリリースの API を読めないとき、`flake.lock` と `sources.json` は変わらず、終了コードは 1 である。
- I8: 更新の後に差分が無いとき、`nix build` と `sudo` は呼ばれず、答えは読まれず、終了コードは 0 である。

境界の入力:

| 入力 | 期待 | 不変条件 |
| --- | --- | --- |
| `aquaskk` の `url` が `https://evil.example/AquaSKK.pkg` | 何も変わらず 1 | I1 |
| `aquaskk` の `url` が `https://github.com/someone/aquaskk/releases/download/…` | 何も変わらず 1 | I1 |
| `claude-desktop` の版が上がり、`aquaskk` の `url` が許す接頭辞の外 | `claude-desktop` の分も書かれず 1 | I1 |
| GitHub の `digest` が別のハッシュ | 何も変わらず 1 | I2 |
| GitHub の `digest` が `null` | 警告を出して続ける | I6 |
| GitHub の API が失敗する | 何も変わらず 1 | I7 |
| 版が変わらず、`nix flake update` も `flake.lock` を変えない | ビルドも確認もせず 0 | I8 |
| 実行の前から `sources.json` に未コミットの変更があり、更新では変わらない | 差分なしとして 0 | I8 |
| GitHub の `digest` が一致し、答え `y` | 差分を出した後に適用する | I4, I5 |
| 答え `YES` | 適用する | I5 |
| 答え `n`、空の行、`yy`、`UPDATE_NIX_TTY` が無いファイル | 適用せず 1 | I3 |
| 答え `y` を標準入力にだけ流す | 適用せず 1 | I3 |

## 受けいれ条件

- A1: `zsh/tests/update-nix.test.zsh` の、上の不変条件の番号を持つテストがすべて通る。dotfiles の CI の `zsh-tests` と shellcheck のジョブも通る。
- A2: 本人が、実際の `bin/update-nix` で、差分と確認の問いが出ること、`n` で適用されないことを確かめる。

## テスト設計

- A1: 境界の入力の表の行を、それぞれテストにする。テストを先に書いて失敗させてから、スクリプトを直す。偽の `curl` は、URL ごとに用意した JSON を返す。テストは `$TMPDIR` に `DOTFILES` の写し (`flake.nix`、`flake.lock`、`nix/pkgs/sources.json`) を git のリポジトリとして作って動かす。テストの名前は `ADR 0139 I1: …` の形にする。
- A2: 手で確かめる。

## トレードオフ

- `bin/update-nix` は、本人が端末の前にいないと適用できない。非対話で更新したいときは `--no-switch` で動かし、差分を読んでから手で適用する。
- 古い AquaSKK のリリースのように `digest` の無いものは、今のとおり Homebrew の `sha256` だけを信じる。
- 許す接頭辞の内側の改ざん (たとえば、正しいホストの別の版) は、ホストの確かめでは防げない。
- GitHub の API の呼び出しが一つ増える。

## 参考文献

- dotfiles の [ADR 0012](0012-remove-homebrew.md)、[ADR 0133](0133-sync-deps-confirm-before-switch.md)
- [docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md)
- https://formulae.brew.sh/api/cask/aquaskk.json
- https://api.github.com/repos/codefirst/aquaskk/releases
