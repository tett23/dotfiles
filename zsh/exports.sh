export LANG=ja_JP.UTF-8
export EDITOR=nvim

export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_RUNTIME_DIR=$HOME/.local/run
export XDG_STATE_HOME=$HOME/.local/state

# PATH の重複エントリを除去 (tmux などのネストシェルで際限なく増えるのを防ぐ)
typeset -U path PATH

# Nix の環境 (PATH・NIX_PROFILES・NIX_SSL_CERT_FILE) は nix-darwin の /etc/zshenv が設定する。
# nix-daemon.sh は NIX_PROFILES を不完全な値で上書きし、tmux の中のシェルで補完が見つからなくなるので
# 読み込まない (docs/adr/0020)

# mise: dotfiles 実体へ symlink した設定を無条件に信頼する (別マシンでの `mise trust` を不要にする)
export MISE_TRUSTED_CONFIG_PATHS="$DOTFILES/mise:$HOME/.config/mise"

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$DOTFILES/bin"

# Homebrew は使わない (Nix と mise に統一。docs/adr/0012)

# PATH の優先順位: mise (言語・ツール。zshrc の mise activate で先頭に入る) → ~/.local/bin・~/bin →
# home-manager (/etc/profiles/per-user) → Nix 本体 → システム。後ろ 3 つは nix-darwin の /etc/zshenv が設定する
# (単体の home-manager は廃止したので ~/.nix-profile/bin は足さない。docs/adr/0023)

# GCP (SDK がインストールされている場合のみ)
if [ -d "$HOME/google-cloud-sdk/bin" ]; then
  export PATH="$PATH:$HOME/google-cloud-sdk/bin"
fi
