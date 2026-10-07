# ADR 0011: zsh の起動と最初のプロンプト表示を速くする

- Status: Accepted
- Date: 2026-10-07

## Context

対話 zsh の、起動から最初のプロンプト表示までが約 0.41 秒 (git リポジトリ内) かかっている。
計測 (zprof、各フックの個別計測) の内訳は次のとおり。

- nix-darwin が生成する `/etc/zshrc`: 約 70 ms。フルの `compinit`、`bashcompinit`、
  プロンプトテーマの読み込み (`promptinit` / `prompt suse`) を毎回実行しているが、
  いずれも自分の `.zshrc` が後から同等の処理をしている (`brew shellenv` も実行しているが、
  Homebrew 自体の廃止を ADR 0012 で扱う)。
- 自分の `.zshrc`: 約 170 ms。zinit のプラグイン読み込み (約 50 ms)、mise の初回フック、`compinit` など。
- 最初のプロンプト直前のフック (`precmd`): git リポジトリ内で約 140 ms。うち `vcs_info` が 64〜110 ms
  (変更の有無の確認を含む)、stash 数の取得が 8 ms。リポジトリ外でも `vcs_info` が 9〜17 ms かかる。
  これは起動時だけでなく、プロンプトを出すたびにかかる。

## Decision

### プロンプトの git 表示 (毎回のプロンプト)
- git リポジトリの内外を、外部コマンドを使わず zsh だけで `.git` を探して判定する。
  リポジトリの外では git を一切起動しない。
- よくある場合 (ブランチ上にいて、rebase / merge / cherry-pick / bisect などの途中でなく、
  `GIT_DIR` も設定されていない) は、`git status --porcelain=v2 --branch --show-stash -uno` 1 回で、
  ブランチ名・staged (`++`)・unstaged (`!!`)・stash 数を求める。
- それ以外 (detached HEAD、各種操作の途中、コミットの無いリポジトリ、`GIT_DIR` 指定時など) は
  従来どおり `vcs_info` に任せる。表示は従来と完全に同じにし、両者を比較するテストで確認する。

### 起動処理
- zinit のプラグインを turbo モード (`wait lucid`) で、最初のプロンプトの直後に読み込む。
  `compinit` は zinit の推奨どおり最後のプラグインの `atinit` で行い、1 日 1 回の検査は維持する。
- `fzf --zsh`、`mise activate zsh`、`direnv hook zsh` の出力を
  `$XDG_CACHE_HOME/zsh` にキャッシュし、コマンド本体が更新されたら作り直す。
- nix-darwin の `/etc/zshrc` の重複処理を flake で止める:
  `programs.zsh.enableGlobalCompInit = false`、`enableBashCompletion = false`、`promptInit = ""`。
  補完ファイルの配置 (`enableCompletion`) は残す。
  反映には `sudo darwin-rebuild switch` が必要なので、本人が実行する。

## Consequences

- 起動と、git リポジトリ内でのプロンプト表示が速くなる。
- 自動補完の候補表示とシンタックスハイライトは、最初のプロンプトが出た直後に有効になる
  (起動直後の一瞬だけ効かない)。
- キャッシュが古くなる可能性に備え、コマンド本体の更新日時で作り直す。
- flake の変更は `sudo darwin-rebuild switch` を実行するまで反映されない。
