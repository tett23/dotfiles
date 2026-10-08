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

# home-manager / nix profile を優先させる
export PATH="$HOME/.nix-profile/bin:$PATH"

# GCP (SDK がインストールされている場合のみ)
if [ -d "$HOME/google-cloud-sdk/bin" ]; then
  export PATH="$PATH:$HOME/google-cloud-sdk/bin"
fi
