# dotfiles ベストプラクティス監査 (2026-10-09 更新)

[2026-10-07 の監査](2026-10-07-best-practices.md) の対応状況を、その後の作業 (ADR 0009〜0023) を反映して更新したもの。
各項目の元の内容と根拠は 2026-10-07 の監査を、直すと挙動が変わる項目の影響は
[2026-10-07-breaking-changes.md](2026-10-07-breaking-changes.md) を参照。

凡例: ✅ 対応済み / 🔶 一部対応 / ⏸ 見送り / ⬜ 未対応

## 対応状況のまとめ

| 状況 | 項目 |
|---|---|
| ✅ 対応済み | Z1, Z5〜Z11, Z13, B1〜B4, B6, I1〜I4, G1, G3〜G5, N1〜N5, V1〜V6, C1, O1, O2, M1, M2, P1〜P6 |
| 🔶 一部対応 | Z4, Z12, B5, G2, T1, C3 |
| ⏸ 見送り | Z2, Z3, N6 |
| ⬜ 未対応 | C2 |

監査後に見つかった項目 (P1〜P6) は下の「監査後に見つかった項目」を参照。

## 今回 (ADR 0023) 対応したもの

- **C1** ✅ `claude/settings.json` の `autoMode.environment` から別リポジトリ (golem) 固有の記述を外し、
  どのリポジトリにも当てはまる記述にした (公開範囲と既定ブランチはリポジトリごとに git のリモートから判断する)。
- **Z6** ✅ zshrc から `~/.local/bin/env` (uv のインストーラが追記したもの) の読み込みを外し、空になった
  `~/.nix-profile/bin` を PATH に足す行も外した。PATH の優先順位は「mise → `~/.local/bin`・`~/bin` → home-manager →
  Nix 本体 → システム」。Homebrew は ADR 0012 で廃止済み。
- **Z7** ✅ 履歴ファイルを `$XDG_STATE_HOME/zsh/history` に移し (旧 `~/.zsh_history` は自動で移動)、
  `hist_ignore_space` と `hist_reduce_blanks` を有効にした。
- **N5** ✅ 公式インストーラ版の claude (`~/.local/bin/claude`、`~/.local/share/claude`) を削除し、Nix 版に一本化した。
- **O2** ✅ VSCode の既定のフォーマッタと JavaScript・TypeScript・JSON・CSS のフォーマッタを biome にし、
  biome の拡張機能を入れた。biome が整形しない HTML・Markdown などは従来どおり。
- **P2** ✅ CI の `actions/checkout` を Node.js 24 で動く v7 に上げた。

## 追加で対応したもの (ADR 0024)

- **B6** ✅ `bin/orch` の別名の既定値を現行の最新にした (`opus` → `claude-opus-5-5`、`sonnet` → `claude-sonnet-5-5`、
  `haiku` → `claude-haiku-5-5`、`fable` → `claude-fable-5-1`)。それぞれ `claude -p --model` で呼べることを確認した。
  `sol` (`gpt-5.6-sol`、OpenAI) は確かめる手段が無いため推定値のまま。
- **P1** ✅ 画面にログインしていない状態で `bootstrap.sh` が失敗したときは、警告を出して `mise install` まで続け、
  ログイン後に `sudo darwin-rebuild switch` を実行するよう案内するようにした。ログインしている状態での失敗は従来どおり止める。
  VM (画面にログインしていないユーザー) で、`install.sh` が最後まで進み終了コード 0 で終わることを確認した。

## 残っている項目

### 未対応

- **C2 [整理]** ステータスライン (`statusLine`) のコンテキスト使用率の表示が、usage-hint mod と重なっている。直すと表示が変わる。

### 一部対応 (残りの部分)

- **Z4 [整理]** `~/dotfiles` という場所の固定が、`tmux/tmux.conf` (`set-environment -g DOTFILES`)、
  `claude/settings.json` (`CLAUDE_CODE_PLUGIN_DIRS`)、`flake.nix` (`dotfilesDirectory`) に残る。
- **Z12 [故障]** fzf のコマンド選択 (`fzf_command_finder`) の `bindkey "^,"` は端末から送れないキー。割り当て先は本人が決める。
- **B5 [陳腐化]** `bin/send-to-kindle` の権限 (`-A`)。絞るには実際の送信で確かめる必要がある。
  dotenv の置き換え (ADR 0014)、`.env` が無いときの環境変数の利用 (ADR 0021)、`--env-file` での指定 (ADR 0022) は対応済み。
- **G2 [陳腐化]** delta のリンク先 (`vscode://`) は好みの問題として変えていない。
- **T1 [陳腐化]** TPM はプラグインのバージョン固定に対応していない (分割時のディレクトリは ADR 0009 で対応済み)。
- **C3 [リスク]** usage-hint mod の型定義 (約 1.4 万行、Claude Code が生成) をコミットするかどうか。CI は ADR 0014 で追加済み。

### 見送り

- **Z2 [リスク]** PATH などを `.zshenv` に移すと、ログインシェルで `path_helper` が PATH を並べ替える (ADR 0010)。
- **Z3 [リスク]** `XDG_RUNTIME_DIR=~/.local/run` は Claude Code のソケット (`cc-socks`) と sbt が使っている (ADR 0010)。
- **N6 [リスク]** mise の言語とツールがすべて `latest` で、ロックファイルも無い (本人の方針)。

## 監査後に見つかった項目

| ID | 内容 | 状況 |
|---|---|---|
| P1 | 画面にログインしていない状態での `curl \| sh` が colima の LaunchAgent の登録で止まる | ✅ ADR 0024 |
| P2 | CI の `actions/checkout@v4` が非推奨の Node.js 20 で動く | ✅ ADR 0023 |
| P3 | 新規マシンで nix-darwin の初回適用が `--extra-experimental-features` を受け付けずに止まる | ✅ ADR 0017 |
| P4 | 新規マシンで mise の ghc が解決できない (ghcup のプラグインはプラグイン名をツール名に使う) | ✅ ADR 0018 |
| P5 | 新規マシンで `~/.config/eskk` のリンクが切れる (eskk.vim は削除) | ✅ ADR 0019 |
| P6 | `nix-daemon.sh` が `NIX_PROFILES` を上書きし、tmux の中で補完関数が見つからない | ✅ ADR 0020 |

P1・P3〜P5 は、macOS の VM (tart) で素の状態から `curl | sh` を流して見つかった。

## その他の主な変更 (監査の項目以外)

- Homebrew を廃止し、GUI アプリも Nix で管理するようにした (ADR 0012)。nixpkgs に無い Claude デスクトップと AquaSKK は
  `nix/pkgs/` に自前のパッケージを作った。
- `dependencies.md` から Claude で設定を生成する `bin/sync-deps` と、最新化の `bin/update-nix`・`bin/update-mise` を置いた
  (ADR 0012, 0013)。
- `curl | sh` でのインストール後、`origin` を SSH の URL にするようにした (ADR 0016)。
- `bin/send-to-kindle` を最新化した (ADR 0021, 0022)。
