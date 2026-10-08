# ADR 0023: 監査の残りのうち C1・Z6・Z7・N5・O2 と CI の Node.js を是正する

- Status: Accepted
- Date: 2026-10-09
- 関連: docs/audit/2026-10-07-best-practices.md

## Context

監査の残りのうち、本人が直すと決めたもの。

- C1: `claude/settings.json` は全リポジトリに効くユーザー設定だが、`autoMode.environment` に別リポジトリ (golem) 固有の
  記述 (リモートの無い非公開リポジトリ、信頼するリポジトリのパス、主な用途、既定ブランチ) が入っている。
- Z6: PATH の先頭が `~/.local/bin` になっている。zshrc の末尾で読み込む `~/.local/bin/env` (uv のインストーラが追記したもの) が
  先頭に足すため、`~/.local/bin` の公式インストーラ版の claude や uv のツールが mise より優先される。
  単体の home-manager を廃止したので `~/.nix-profile/bin` は空。
- Z7: 履歴ファイルがホーム直下 (`~/.zsh_history`) にあり、`hist_ignore_space`・`hist_reduce_blanks` が無効。
- N5: claude CLI が公式インストーラ版 (`~/.local/bin/claude` → `~/.local/share/claude`) と Nix 版の二重になっている。
- O2: VSCode の既定のフォーマッタが deno (`denoland.vscode-deno`) で、Node のプロジェクトの TypeScript も deno で整形される。
- CI の `actions/checkout@v4` は非推奨の Node.js 20 で動いている。

## Decision

- C1: golem 固有の記述を外し、どのリポジトリにも当てはまる記述にする (公開範囲と既定ブランチはリポジトリごとに git の
  リモートから判断する)。リポジトリ固有の内容は各リポジトリの `.claude/settings.json` に置く。
- Z6: zshrc から `~/.local/bin/env` の読み込みを削除する (`~/.local/bin` は exports.sh で既に PATH に入っている)。
  空になった `~/.nix-profile/bin` を PATH の先頭に足す行も削除する。
  優先順位は「mise (言語・ツール) → `~/.local/bin`・`~/bin` → home-manager → Nix 本体 → システム」とする。
- Z7: 履歴ファイルを `$XDG_STATE_HOME/zsh/history` に移す。新しい場所に無く、旧 `~/.zsh_history` があれば移動する。
  `hist_ignore_space` と `hist_reduce_blanks` を有効にする。
- N5: 公式インストーラ版の claude を削除し、Nix 版 (dependencies.md の claude-code) に一本化する。ファイルはゴミ箱に移す。
- O2: VSCode の既定のフォーマッタを biome (`biomejs.biome`) にし、biome が整形できる JavaScript・TypeScript・JSON・CSS も
  biome にする。biome が整形しない言語 (HTML・Markdown など) は従来どおり。biome の拡張機能を入れる。
- CI: `actions/checkout` を Node.js 24 で動く最新 (v7) に上げる。

## Consequences

- 対話シェルの PATH で、`~/.local/bin` のツールより mise の言語・ツールが優先される。
- 既に開いているシェルは旧 `~/.zsh_history` に書き続けるので、移行後はシェルを開き直す。
  先頭が空白のコマンドは履歴に残らなくなる。
- `claude` コマンドは Nix 版になる (更新は bin/update-nix)。
- VSCode で JavaScript・TypeScript・JSON・CSS の保存時の整形結果が変わる。
- auto mode の判断材料が、golem 前提から一般的な記述に変わる。
