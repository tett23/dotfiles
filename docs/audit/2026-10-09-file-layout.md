# dotfiles ファイル配置の監査 (2026-10-09)

リポジトリ内のファイル配置と、ホームディレクトリへのリンク先 (`flake.nix` の `home.file` / `xdg.configFile`) を、
次の基準で点検した。

- **XDG Base Directory**: 設定は `~/.config`、状態は `~/.local/state`、データは `~/.local/share` に置き、
  ホーム直下にドットファイルを増やさない。ツールが XDG の場所に対応していればそちらを使う。
- **リポジトリ内の対称性**: リポジトリ内のパスと、リンク先のパスの対応が推測しやすい (ツールごとのディレクトリ)。
- **役割の分離**: 本人の設定、このリポジトリ用の設定、生成物・状態が混ざらない。

直すと挙動が変わるもの (リンク先が変わる、読み込み順が変わるなど) には「挙動」を付けた。直す優先度は本人が決める。

凡例: [XDG] XDG の場所に移せる / [対称] リポジトリ内の配置の不揃い / [重複] 同じ役割のファイルが複数ある /
[文書] ルールで求められている文書・命名との不一致

## まとめ

| ID | 区分 | 内容 | 挙動 |
|---|---|---|---|
| L1 | 重複 | `CLAUDE.md` と `.claude/CLAUDE.md` の内容が重なり、ADR のコミット時期の指示が食い違う | あり |
| L2 | 対称 | Claude Code の本人設定が `claude/` と `.claude/` に分かれている | あり |
| L3 | XDG | git の設定がホーム直下 (`~/.gitconfig`、`~/.gitignore_global`) | あり |
| L4 | XDG | tmux の設定がホーム直下 (`~/.tmux.conf`)、TPM のプラグインが `~/.tmux/plugins` | あり |
| L5 | XDG | zsh の設定がホーム直下 (`~/.zshrc`)。`ZDOTDIR` を使っていない | あり |
| L6 | XDG | rubocop の設定がホーム直下 (`~/.rubocop.yml`) | あり |
| L7 | 対称 | ルート直下の単独ファイル (`bat-config`、`gitconfig`、`gitignore_global`、`rubocop.yml`) | なし |
| L8 | 対称 | `bin/` のスクリプトを PATH の末尾に `$DOTFILES/bin` で足している | あり |
| L9 | 対称 | テストの置き場所がツールごとにばらばら | なし |
| L10 | 文書 | `docs/specifications.md` が無い | なし |
| L11 | 文書 | ADR のファイル名の連番が 4 桁 (ルールの例は 5 桁) | なし |
| L12 | その他 | リポジトリ直下に `.gitignore` が無く、`.DS_Store` などを本人の global ignore に頼っている | なし |

## 各項目

### L1 [重複] `CLAUDE.md` と `.claude/CLAUDE.md`

- `CLAUDE.md` (リポジトリ直下) と `.claude/CLAUDE.md` は、どちらも Claude Code がこのリポジトリのプロジェクト指示として読む。
- `.claude/CLAUDE.md` は `flake.nix` で `~/.claude/CLAUDE.md` (全リポジトリ共通の本人指示) にもリンクしているため、
  このリポジトリでは同じ内容が 2 回読み込まれる。
- 内容も食い違っている。`CLAUDE.md` は「コミット後の ADR の修正は禁止」で、作成時にコミットしてよいと読める。
  `.claude/CLAUDE.md` は「作成時点ではコミットせず、人間のレビューを受ける」。
- 案: 全リポジトリ共通の指示は `claude/CLAUDE.md` に置いて `~/.claude/CLAUDE.md` にリンクし (L2 と合わせる)、
  このリポジトリ固有の指示 (TDD、Rust の書き方など) だけを `CLAUDE.md` に残す。

### L2 [対称] Claude Code の本人設定が 2 か所に分かれている

- `~/.claude/settings.json` のリンク元は `claude/settings.json`、`~/.claude/CLAUDE.md` のリンク元は `.claude/CLAUDE.md`。
  同じ `~/.claude/` に置くものなのに、リポジトリ内の場所が違う。
- `.claude/` はこのリポジトリ用 (プロジェクト設定、`.claude/skills/sync-deps`) の場所でもあるため、
  本人の全体設定と混ざっている。
- 案: 本人の全体設定は `claude/` (リンク元)、このリポジトリ用は `.claude/` に揃える。

### L3 [XDG] git の設定

- `~/.gitconfig` と `~/.gitignore_global` にリンクしている。
- git は `~/.config/git/config` と `~/.config/git/ignore` を標準で読む。後者は `core.excludesFile` を書かなくても使われる。
- 案: `git/config`・`git/ignore` に移して `xdg.configFile."git"` でリンクし、`gitconfig` の `excludesfile` を外す。
  旧リンク (`~/.gitconfig`) が残っていると、そちらも読まれる点に注意。

### L4 [XDG] tmux の設定と TPM のプラグイン

- `~/.tmux.conf` にリンクしている。tmux 3.1 以降は `~/.config/tmux/tmux.conf` を読む (手元は 3.7c)。
- TPM のプラグインは既定の `~/.tmux/plugins` に入っている。`TMUX_PLUGIN_MANAGER_PATH` で
  `~/.local/share/tmux/plugins` などに移せる。
- `tmux/tmux.conf` の再読み込みのキー割り当て (`bind r`) が `~/.tmux.conf` を直接指しているため、移すならここも変える。

### L5 [XDG] zsh の設定

- `~/.zshenv` と `~/.zshrc` にリンクしている。`~/.zshenv` で `ZDOTDIR=~/.config/zsh` を設定すれば、
  ホーム直下は `~/.zshenv` だけになる。
- 履歴 (`$XDG_STATE_HOME/zsh/history`) は ADR 0023 で移動済み。補完のキャッシュ (`.zcompdump`) の置き場所も合わせて確認が要る。
- ログインシェルの読み込み順に関わるため、ADR 0010 (Z2 の見送り) と合わせて検討する。

### L6 [XDG] rubocop の設定

- `~/.rubocop.yml` にリンクしている。RuboCop は `~/.config/rubocop/config.yml` も読む。

### L7 [対称] ルート直下の単独ファイル

- `ghostty/config`、`mise/config.toml` のようにツール名のディレクトリに置くものと、
  `bat-config`、`gitconfig`、`gitignore_global`、`rubocop.yml` のようにルートに置くものが混ざっている。
- 案: `bat/config`、`git/config`、`git/ignore`、`rubocop/config.yml` のように、リンク先 (`~/.config/<ツール>/…`) と
  同じ形にする。リンク先を変えずにリポジトリ内の場所だけ揃えることもできる (その場合は挙動は変わらない)。

### L8 [対称] `bin/` の PATH への追加

- `zsh/exports.sh` で `$DOTFILES/bin` を PATH の末尾に足している。zsh 以外 (launchd、他のシェル、GUI アプリ) からは見えず、
  同名のコマンドがあるとそちらが優先される。
- 案: home-manager で `~/.local/bin` にリンクする (`home.file.".local/bin/<名前>"`)。

### L9 [対称] テストの置き場所

- zsh は `zsh/tests/`、usage-hint mod は `claude/mods/usage-hint/tests/`、send-to-kindle は本体の中 (ADR 0025)。
- それぞれ理由がある (send-to-kindle は 1 ファイルにする必要がある) ため、統一するより、
  テストの実行方法を README か CI の定義にまとめておく程度でよい。

### L10 [文書] `docs/specifications.md` が無い

- `.claude/CLAUDE.md` のルールでは、ADR で仕様が変わったら `docs/specifications.md` と README を同時に更新し、
  破棄した ADR の理由もそこに書く。現在このファイルは無い。

### L11 [文書] ADR のファイル名

- ルールの例は `00001-feature-details.md` (5 桁) だが、既存の ADR は `0001-…`〜`0025-…` (4 桁)。
  ADR はコミット後に変更できないため、改名するかどうか (改名は内容の変更に当たるか) を決める必要がある。

### L12 [その他] リポジトリの `.gitignore`

- リポジトリ直下に `.gitignore` が無い。`.DS_Store` や `.ruby-lsp/` は本人の global ignore (`gitignore_global`) で
  無視されているため、別の環境で clone すると追跡対象に見える。
- 案: リポジトリ直下に `.gitignore` を置き、このリポジトリで出るもの (`.DS_Store` など) を書く。

## その後の対応

- **L1** 🔶 リポジトリ直下の `CLAUDE.md` を削除した。`.claude/CLAUDE.md` が `~/.claude/CLAUDE.md` にもリンクされていて
  このリポジトリで 2 回読み込まれる点は残る。
- **L10** ✅ `docs/specifications.md` を作成した。
- **L11** ✅ ルール側の例を 4 桁 (`0001-feature-details.md`) に直し、既存の ADR に合わせた。

## 問題が無かったもの

- `nvim/`、`karabiner/`、`ghostty/`、`mise/` は `~/.config/<ツール>` にリンクしており、XDG に沿っている。
- VSCode と AquaSKK は macOS の決まった場所 (`~/Library/Application Support/…`) にリンクしている。
- zsh の履歴は `$XDG_STATE_HOME` にある (ADR 0023)。
- `karabiner/` は Karabiner-Elements が書き込む `automatic_backups` を `karabiner/.gitignore` で除外している。

## リポジトリ外 (参考)

ホーム直下に `node_modules`、`package-lock.json`、`yarn.lock`、`perl5` がある。dotfiles の管理外だが、
ホーム直下で `npm install` などを実行した名残と思われる。
