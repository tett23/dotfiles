#!/bin/sh
#
# install.sh - curl | sh 用のエントリポイント (冪等)
#
# 使い方:
#   curl -fsSL https://raw.githubusercontent.com/tett23/dotfiles/HEAD/install.sh | sh
#
# やること (docs/adr/0001-curl-sh-install.md):
#   1. Xcode Command Line Tools の確認 / インストール
#   2. リポジトリを $DOTFILES に HTTPS で clone (既にあれば pull)
#   3. submodule の取得
#   4. bootstrap.sh (Nix → nix-darwin / home-manager / Homebrew Cask)
#   5. setup/install.sh (シンボリックリンク)
#   6. mise install (言語 / ツール)
#
# 環境変数で上書き可能: DOTFILES, DOTFILES_REPO, DOTFILES_BRANCH
#
# NOTE: `| sh` で実行されるため POSIX sh で書くこと。
#       ダウンロードが途中で切れても部分実行されないよう、全体を main で包んでいる。
set -eu

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/tett23/dotfiles.git}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-master}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> WARN:\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31m==> ERROR:\033[0m %s\n' "$*" >&2
  exit 1
}

# .gitmodules 等の SSH URL を、SSH 鍵の無い新規マシンでも取得できるよう HTTPS に読み替える
git_https() {
  git -c url.https://github.com/.insteadOf=git@github.com: "$@"
}

# 1. Xcode Command Line Tools (git に必要)
ensure_xcode_clt() {
  [ "$(uname -s)" = "Darwin" ] || return 0
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools はインストール済み"
    return 0
  fi

  log "Xcode Command Line Tools をインストールします (GUI のダイアログに従ってください)"
  xcode-select --install >/dev/null 2>&1 || true

  # curl | sh では stdin がスクリプト本体なので read では待てない。ポーリングする
  until xcode-select -p >/dev/null 2>&1; do
    sleep 5
  done
  log "Xcode Command Line Tools をインストールしました"
}

# 2. リポジトリの取得
fetch_repo() {
  if [ -d "$DOTFILES/.git" ]; then
    log "リポジトリは取得済み: $DOTFILES (pull --ff-only を試みます)"
    git_https -C "$DOTFILES" pull --ff-only ||
      warn "pull できませんでした。現在の内容のまま続行します"
    return 0
  fi

  if [ -e "$DOTFILES" ]; then
    die "$DOTFILES が既に存在しますが git リポジトリではありません"
  fi

  log "clone します: $DOTFILES_REPO → $DOTFILES"
  git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES"
}

# 3. submodule
fetch_submodules() {
  log "submodule を取得します"
  git_https -C "$DOTFILES" submodule update --init --recursive
}

# 4. Nix / nix-darwin。対話入力 (sudo 等) のため、可能なら端末を stdin に渡す
run_bootstrap() {
  log "bootstrap.sh を実行します"
  if (: </dev/tty) 2>/dev/null; then
    "$DOTFILES/bootstrap.sh" </dev/tty
  else
    "$DOTFILES/bootstrap.sh"
  fi
}

# 5. シンボリックリンク
link_dotfiles() {
  log "シンボリックリンクを作成します"
  DOTFILES="$DOTFILES" sh "$DOTFILES/setup/install.sh"
}

# 6. mise 管理の言語 / ツール
install_mise_tools() {
  # nix-darwin / home-manager 適用直後は PATH に入っていないため明示的に追加する
  PATH="/etc/profiles/per-user/$(id -un)/bin:/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
  export PATH

  if ! command -v mise >/dev/null 2>&1; then
    warn "mise が見つかりません。新しいシェルで 'mise install' を実行してください"
    return 0
  fi

  log "mise install を実行します (初回は時間がかかります)"
  mise install --yes ||
    warn "mise install が失敗しました。新しいシェルで 'mise install' を再実行してください"
}

main() {
  log "dotfiles のインストールを開始します (dest: $DOTFILES)"
  ensure_xcode_clt
  fetch_repo
  fetch_submodules
  run_bootstrap
  link_dotfiles
  install_mise_tools
  log "すべて完了しました。新しいシェルを開いてください。"
}

main "$@"
