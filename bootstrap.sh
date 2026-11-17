#!/usr/bin/env bash
#
# bootstrap.sh - 初回セットアップ用スクリプト (冪等)
#
# 何度実行しても安全:
#   1. Nix が無ければインストール
#   2. nix-darwin (flake) を適用して CLI / GUI アプリを一括構築 (Homebrew は使わない)
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

  # GUI インストーラの完了を待つ。install.sh と同じく、Enter を待たずに 5 秒ごとに確かめる (docs/adr/0055)
  log "Xcode Command Line Tools のインストール完了を待機中..."
  until xcode-select -p >/dev/null 2>&1; do
    sleep 5
  done
  log "Xcode Command Line Tools をインストールしました"
}

# Nix のインストーラー。版を固定し、中身の sha256 が一致するときだけ動かす (docs/adr/0046、docs/adr/0141)。
# 版を上げるときは、URL とハッシュを一緒に書き換える
NIX_INSTALLER_URL="https://install.determinate.systems/nix/tag/v3.24.1"
NIX_INSTALLER_SHA256=1470fa510a9e3e8d8e03c7dc50f89c22003a0d7077a43486b6a3e97e3dde6160

# インストーラーを一時ファイルに取り、sha256 を確かめてから動かす。Nix の前に動くので curl と shasum だけを使う
install_nix() {
  local tmp actual
  tmp="$(mktemp "${TMPDIR:-/tmp}/nix-installer.XXXXXX")"
  if ! curl --proto '=https' --tlsv1.2 -sSf -L -o "$tmp" "$NIX_INSTALLER_URL"; then
    rm -f "$tmp"
    echo "Nix のインストーラーを取得できませんでした: $NIX_INSTALLER_URL" >&2
    exit 1
  fi
  actual="$(shasum -a 256 "$tmp" | awk '{print $1}')"
  if [ "$actual" != "$NIX_INSTALLER_SHA256" ]; then
    rm -f "$tmp"
    echo "Nix のインストーラーの sha256 ($actual) が、書いた値 ($NIX_INSTALLER_SHA256) と違います。動かさずに終わります。" >&2
    exit 1
  fi
  sh "$tmp" install --no-confirm
  rm -f "$tmp"
}

# 1. Nix のインストール (未導入のときだけ)
ensure_nix() {
  load_nix_env
  if command -v nix >/dev/null 2>&1; then
    log "Nix はインストール済み: $(nix --version)"
    return
  fi

  log "Nix が見つからないためインストールします (Determinate Systems installer)"
  install_nix

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
    # 実験的機能の指定は nix に渡す (darwin-rebuild は受け付けない)。
    # nix-darwin は flake.lock で固定した版を使う (docs/adr/0017)
    sudo nix --extra-experimental-features "${NIX_FEATURES}" \
      run --inputs-from "${FLAKE_DIR}" nix-darwin -- \
      switch --flake "${FLAKE_DIR}#${HOSTNAME_TARGET}"
  fi
}

main() {
  log "bootstrap 開始 (flake: ${FLAKE_DIR}, host: ${HOSTNAME_TARGET})"
  ensure_xcode_clt
  ensure_nix
  apply_darwin
  log "完了しました。新しいシェルを開くと反映されます。"
}

# source されたときは関数の定義だけ行う (テスト用。docs/adr/0141)
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
