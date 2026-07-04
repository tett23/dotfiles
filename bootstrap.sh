#!/usr/bin/env bash
#
# bootstrap.sh - 初回セットアップ用スクリプト (冪等)
#
# 何度実行しても安全:
#   1. Nix が無ければインストール
#   2. nix-darwin (flake) を適用して Homebrew 本体 / CLI / Cask を一括構築
#
# 使い方:
#   ./bootstrap.sh
#
set -euo pipefail

# このスクリプトが置かれているディレクトリ (= flake.nix のある場所)
FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTNAME_TARGET="dione"
NIX_FEATURES="nix-command flakes"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# Nix のプロファイルを現在のシェルに読み込む (インストール直後/未読込でも nix を使えるように)
load_nix_env() {
  if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
}

# 0. Xcode Command Line Tools のインストール (未導入のときだけ)
ensure_xcode_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools はインストール済み"
    return
  fi

  log "Xcode Command Line Tools が見つからないためインストールします"
  xcode-select --install || true

  # GUI インストーラの完了を待つ
  until xcode-select -p >/dev/null 2>&1; do
    log "Xcode Command Line Tools のインストール完了を待機中... (完了したら Enter)"
    read -r _
  done
  log "Xcode Command Line Tools をインストールしました"
}

# 1. Nix のインストール (未導入のときだけ)
ensure_nix() {
  load_nix_env
  if command -v nix >/dev/null 2>&1; then
    log "Nix はインストール済み: $(nix --version)"
    return
  fi

  log "Nix が見つからないためインストールします (Determinate Systems installer)"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm

  load_nix_env
  if ! command -v nix >/dev/null 2>&1; then
    echo "Nix のインストール後も nix コマンドが見つかりません。新しいシェルを開いて再実行してください。" >&2
    exit 1
  fi
  log "Nix をインストールしました: $(nix --version)"
}

# 2. nix-darwin の適用 (switch 自体が冪等: 差分が無ければ no-op)
apply_darwin() {
  if command -v darwin-rebuild >/dev/null 2>&1; then
    log "darwin-rebuild で適用します"
    sudo darwin-rebuild switch --flake "${FLAKE_DIR}#${HOSTNAME_TARGET}"
  else
    log "darwin-rebuild が未導入のため nix run で初回適用します"
    sudo nix run nix-darwin -- switch \
      --flake "${FLAKE_DIR}#${HOSTNAME_TARGET}" \
      --extra-experimental-features "${NIX_FEATURES}"
  fi
}

main() {
  log "bootstrap 開始 (flake: ${FLAKE_DIR}, host: ${HOSTNAME_TARGET})"
  ensure_xcode_clt
  ensure_nix
  apply_darwin
  log "完了しました。新しいシェルを開くと反映されます。"
}

main "$@"
