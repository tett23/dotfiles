# dotfiles ファイル配置の監査 (2026-10-11 更新)

[2026-10-09 のファイル配置の監査](2026-10-09-file-layout.md) の対応状況を、その後の作業 (ADR 0027〜0039) を反映して更新したもの。
各項目の元の内容と基準は 2026-10-09 の監査を参照。監査レポートはコミット後に変更しないので、新しいファイルとして出す。

凡例: ✅ 対応済み / 🔶 一部対応 / ⬜ 未対応

## 対応状況のまとめ

| 状況 | 項目 |
|---|---|
| ✅ 対応済み | L2, L7, L9, L10, L11, L12 |
| 🔶 一部対応 | L1, L4 |
| ⬜ 未対応 | L3, L5, L6, L8 |

新しく見つかった項目 (L13〜L16) は下の「今回見つかった項目」を参照。

## 対応済み

- **L2** ✅ Claude Code の本人の設定と mod を `.claude/` にまとめ、`claude/` を無くした (ADR 0030)。
  `~/.claude/settings.json` と `~/.claude/CLAUDE.md` のリンク元は、どちらも `.claude/` にある。
- **L7** ✅ ルート直下の単独のファイルを、ツール名のディレクトリに移した (`bat/config`・`git/config`・`git/ignore`・
  `rubocop/config.yml`。ADR 0027)。リンク先は変えていない。
- **L9** ✅ テストの置き場所と実行コマンドを README にまとめた (ADR 0027)。その後、zsh のテストは 4 つに増えた
  (`zsh/tests/`。ADR 0033, 0038)。send-to-kindle は別のリポジトリに移った (ADR 0031)。
- **L10** ✅ `docs/specifications.md` を作った。
- **L11** ✅ ADR のファイル名の連番を 4 桁とした (共通の指示の例を既存の ADR に合わせた)。
- **L12** ✅ リポジトリ直下に `.gitignore` を置いた (ADR 0027)。

## 一部対応 (残りの部分)

- **L1 [重複]** リポジトリ直下の `CLAUDE.md` は削除した。`.claude/CLAUDE.md` は全リポジトリ共通の指示
  (`~/.claude/CLAUDE.md` のリンク元) と、このリポジトリのプロジェクトの指示を兼ねている。ADR 0030 で
  `.claude/settings.json` も同じく兼ねる形にした (トレードオフとして受け入れた)。
  - 2026-10-09 の監査で「同じ内容が 2 回読み込まれる」としたのは誤りだった。Claude Code は実体が同じファイルを
    1 回だけ読み込む。
  - 残るのは、dotfiles 専用の指示・設定を書く場所が無いこと (設定は git の管理外の `.claude/settings.local.json` だけ)。
- **L4 [XDG]** TPM をやめ、tmux-nova を Nix で入れて `~/.config/tmux/plugins/tmux-nova` にリンクした (ADR 0029)。
  `~/.tmux/plugins` は無くなった。tmux の設定は `~/.tmux.conf` のまま (tmux 3.1 以降は `~/.config/tmux/tmux.conf` も読む)。

## 未対応

- **L3 [XDG]** git の設定のリンク先が `~/.gitconfig`・`~/.gitignore_global` のまま (`~/.config/git/config`・
  `~/.config/git/ignore` に移せる)。リポジトリ内の場所は `git/` に揃った (ADR 0027) ので、`flake.nix` のリンク先と
  `git/config` の `excludesfile` を変えるだけで済む。直すと挙動が変わる。
- **L5 [XDG]** zsh の設定が `~/.zshrc` のまま。`ZDOTDIR` を使えば `~/.config/zsh/` に移せる。直すと挙動が変わる。
- **L6 [XDG]** rubocop の設定のリンク先が `~/.rubocop.yml` のまま (`~/.config/rubocop/config.yml` に移せる)。
  リポジトリ内の場所は `rubocop/config.yml` に揃った (ADR 0027)。直すと挙動が変わる。
- **L8 [対称]** `bin/` のスクリプトを、zsh の PATH の末尾に `$DOTFILES/bin` で足しているだけで、zsh 以外からは見えない。
  自作のツール (send-to-kindle・shorten-path・adr-guard) は mise で入れるようになった (ADR 0031, 0032) ので、
  `bin/` に残るのは dotfiles の保守用のスクリプトと小さな短縮コマンドだけ。直すと挙動が変わる。

## 今回見つかった項目

| ID | 区分 | 内容 | 挙動 |
|---|---|---|---|
| L13 | 残骸 | `.vscode/settings.json` の `"deno.enable": true` が、Deno のコードが無くなった後も残っている | なし |
| L14 | 残骸 | ホームに空の `~/.tmux/` が残っている (TPM のプラグインの置き場所。ADR 0029 で中身は削除済み) | なし |
| L15 | 残骸 | `install.sh` の submodule の取得 (`fetch_submodules`) が、submodule が無くなった後も残っている | なし |
| L16 | 対称 | tmux のスクリプトが `tmux/segments/` (ステータスラインの表示用) と `tmux/scripts/` (キーの割り当て用) に分かれている | なし |

- **L13** `bin/send-to-kindle` (Deno) は ADR 0031 で削除し、リポジトリに Deno のコードは無い。VSCode でこのリポジトリを
  開くと、Deno の言語サーバーが有効になる。
- **L14** dotfiles の外のため、本人が `rmdir ~/.tmux` で消す。
- **L15** ADR 0029 では、今後 submodule を足したときのために残すと決めた。submodule が無い間は何もしない。
  残骸として整理するかは改めて判断する。
- **L16** 用途が違うので分けてもよいが、`tmux/scripts/` 1 か所にまとめることもできる。CI の shellcheck の対象は両方とも入っている。

## 問題が無かったもの

- 2026-10-09 の監査で問題が無かったもの (`nvim/`・`karabiner/`・`ghostty/`・`mise/` の XDG のリンク、VSCode と AquaSKK の
  macOS の決まった場所へのリンク、zsh の履歴の XDG の場所) は変わっていない。
- 新しく足したもの (`.githooks/`・`zsh/lib/`・`zsh/tests/`・`.claude/mods/`・`tmux/scripts/`) は、用途ごとのディレクトリに置いている。
- tmux-nova は XDG の場所 (`~/.config/tmux/plugins/`) にリンクしている。
