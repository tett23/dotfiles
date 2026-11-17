# ADR 0142: zinit と lazy.nvim の本体を、固定のコミットに切り替えられないときは読み込まない

Status: accepted

## 文脈

zsh のプラグインは zinit で、nvim のプラグインは lazy.nvim で入れる。
どちらのプラグインも、コミットに固定している (zsh は `zsh/plugins.sh` の `ver`、nvim は `nvim/lazy-lock.json`)。
zinit 本体も、`zsh/plugins.sh` の `_zinit_rev` で固定している ([ADR 0046](0046-fix-audit-non-breaking.md))。

2026-11-16 のセキュリティの監査 ([docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md) の指摘 7) は、次の三つを重大度「低」の問題として挙げた。

- zinit 本体を版なしで clone し、固定のコミットに切り替えられなくても、警告を出すだけで読み込む (fail-open)。
- lazy.nvim 本体を、`--branch=stable` の先頭で取る。
- mason の `ensure_installed` で入れるツールの版を、固定していない。

本人は、ADR を作って扱うと決めた。
本人は、版の固定は運用が重くなるので、更新の仕組みを足さずに済む範囲で守ることを望む ([ADR 0134](0134-mise-lockfile-checksums.md))。
そのため、この ADR で、すでに固定しているコミットに切り替えられないときは読み込まない (fail-closed) ことと、lazy.nvim 本体を lockfile のコミットに合わせることだけを決める。
mason のツールは固定しない。

## 調査した事項

- `zsh/plugins.sh` は、`zinit.zsh` が無ければ `git clone https://github.com/zdharma-continuum/zinit` で版なしで clone する (4〜10 行)。clone に失敗しても、`The clone has failed.` を出すだけである (9 行)。
- 同じファイルは、`.git` があり HEAD が `_zinit_rev` (`cb4968123979cf073384e93aa8066d8fd450580f`。3 行) と違えば、`fetch` と `checkout` で切り替える (12〜16 行)。`checkout` に失敗しても、警告を出すだけで、18 行の `source "$_zinit_dir/zinit.zsh"` に進む。
- プラグインは、`zinit ice ver"<コミット>"` で固定している (24、33、35 行)。
- `nvim/lua/config/lazy.lua` は、`lazy.nvim` が無ければ `git clone --filter=blob:none --branch=stable https://github.com/folke/lazy.nvim.git` で取る (4〜8 行)。clone に失敗したら、理由を出して `os.exit(1)` で止まる (9〜17 行)。
- `nvim/lazy-lock.json` の 15 行は、`"lazy.nvim": { "branch": "main", "commit": "306a05526ada86a7b30af95c5cc81ffba93fef97" }` である。新しい機械で最初に clone する `stable` の先頭が、このコミットと同じかは、確かめていない。lazy.nvim が、起動の後に自分自身を lockfile のコミットに合わせるかも、確かめていない。
- mason-lspconfig の `ensure_installed` (`nvim/lua/plugins/lsp.lua` の 42 行あたり) は、版を書く形を持たない (mason-lspconfig の README に、版を書く例が無い)。mason-tool-installer (`lsp.lua` の 52 行、`ensure_installed` は 57 行) は、`{ "stylua", version = "…" }` の形で版を固定できる (`mason-tool-installer.nvim` の README の 59〜60 行)。mason、mason-lspconfig、mason-tool-installer のプラグインそのものは、`lazy-lock.json` の 18〜20 行でコミットに固定している。

## 実装すること

- `zsh/plugins.sh` は、`source` の直前に `git -C "$_zinit_dir" rev-parse HEAD` が `_zinit_rev` と同じかを確かめ、違うとき (clone の失敗、`checkout` の失敗を含む) は、`zinit.zsh` を読み込まず、zinit とプラグインの設定 (19〜36 行) を飛ばす。`fetch` の失敗だけでは決めない。手元にコミットがあれば、`checkout` は成功するためである。警告は今のとおり出す。シェルはプラグイン無しで起動する。`zsh/completions.sh` の zinit を使う箇所 (22、39 行) は `${+functions[zinit]}` で守られているので、読み込まなくても壊れない。
- zinit の clone の URL を、変数 `_zinit_url` (既定は今の URL) にする。テストから差し替えるためである。
- `nvim/lua/config/lazy.lua` は、`lazy.nvim` を clone した直後に、`nvim/lazy-lock.json` の `lazy.nvim` の `commit` を読み、`git -C <lazypath> checkout <commit>` で切り替える。切り替えに失敗したら、clone の失敗と同じく理由を出して止まる。
  - `lazy-lock.json` は、`vim.fn.stdpath("config") .. "/lazy-lock.json"` から `vim.json.decode` で読む。
  - clone の `--filter=blob:none` では、古いコミットへの `checkout` で blob を取りに行く。取れないときは、上のとおり止まる。
- `docs/specifications.md` の zsh と nvim の項に、固定のコミットに切り替えられないときは読み込まないことを書く。

## 実装しないこと

- mason で入れるツール (LSP サーバー、stylua など) の版を固定すること。版を上げる手間が増えるので、`latest` と同じ扱いにする (本人の方針)。
- lazy.nvim が、すでに入っている lazy.nvim 本体を lockfile のコミットに合わせるかを変えること。clone した直後だけを扱う。
- zinit のプラグインの `ver` の扱いを変えること。

## 不変条件

- I1: `zsh/plugins.sh` を読んだとき、zinit 本体の HEAD が `_zinit_rev` でなければ、`zinit.zsh` は読み込まれず、`zinit` の関数は定義されない。
- I2: `zsh/plugins.sh` を読んだとき、zinit 本体の HEAD が `_zinit_rev` なら、`zinit.zsh` を読み込む。
- I3: `lazy.lua` が lazy.nvim を clone したとき、`lazy-lock.json` の `lazy.nvim` の `commit` に切り替えられなければ、nvim は終了コード 1 で止まる。

境界の入力:

| 入力 | 期待 | 不変条件 |
| --- | --- | --- |
| zinit の偽のリポジトリの HEAD が `_zinit_rev` と違い、`_zinit_rev` を持たない | `zinit` が定義されない | I1 |
| zinit の clone が失敗する (URL を向け先の無いものにする) | `zinit` が定義されない | I1 |
| zinit の偽のリポジトリの HEAD が `_zinit_rev` | `zinit.zsh` を読み込む | I2 |
| `lazy-lock.json` の `commit` が、clone したリポジトリに無い | 止まる | I3 |

## 受けいれ条件

- A1: `zsh/tests/plugins.test.zsh` の、I1 と I2 の番号を持つテストが通る。
- A2: 本人が `nvim` の data を退かした新しい状態で起動し、`lazy.nvim` が `lazy-lock.json` のコミットになっていることを `git -C ~/.local/share/nvim/lazy/lazy.nvim rev-parse HEAD` で確かめる。
- A3: I3 は、本人が nvim の設定を `~/.config/nvim-adr0142` に写し、その `lazy-lock.json` の `lazy.nvim` の `commit` を無いコミット (`0000…`) にして、`NVIM_APPNAME=nvim-adr0142 nvim` を動かして確かめる。理由が出てキーを待ち、キーを押すと終了コード 1 で終わる (`lazy.lua` の 15〜16 行の `getchar()` と `os.exit(1)`)。確かめた後に、写した設定と data を消す。
- A4: dotfiles の CI の `zsh-tests` のジョブが通る。

## テスト設計

- A1: zinit の取得元と置き場所を、テストから差し替えられるようにする (今の `_zinit_dir` と同じく、変数で持つ)。`$TMPDIR` に偽の zinit のリポジトリ (`zinit.zsh` に `zinit() { :; }` だけを書く) を作り、境界の入力の表の I1 と I2 の行をテストにする。テストを先に書いて失敗させる。テストの名前は `ADR 0142 I1: …` の形にする。
- A2、A3: ネットワークと nvim の data を使うので、手で確かめる。

## トレードオフ

- zinit の取得元に届かない新しい機械では、シェルはプラグイン無しで起動する。今は、警告の後に `source` の失敗と `command not found` が続く。
- `lazy.lua` が `lazy-lock.json` を読むので、lockfile の形が変わると、起動の前に止まりうる。
- mason のツールは、取得元が侵されると、そのまま入る。

## 参考文献

- [docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md)
- dotfiles の [ADR 0046](0046-fix-audit-non-breaking.md)、[ADR 0134](0134-mise-lockfile-checksums.md)
- `mason-tool-installer.nvim` の README
