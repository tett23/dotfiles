export LANG=ja_JP.UTF-8
export EDITOR=nvim

export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_RUNTIME_DIR=$HOME/.local/run
export XDG_STATE_HOME=$HOME/.local/state

# PATH の重複エントリを除去 (tmux などのネストシェルで際限なく増えるのを防ぐ)
typeset -U path PATH

# Nix
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# mise: dotfiles 実体へ symlink した設定を無条件に信頼する (別マシンでの `mise trust` を不要にする)
export MISE_TRUSTED_CONFIG_PATHS="$DOTFILES/mise:$HOME/.config/mise"

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$DOTFILES/bin"

if test "$(uname -s)" = "Darwin" ; then
  # Homebrew の PATH / FPATH / MANPATH などは brew 自身に設定させる (docs/adr/0010)
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
  fi

  # NOTE: homebrew LLVM の clang を PATH 先頭に置くと -lSystem を解決できずビルドが壊れるため無効化。
  # 必要なときだけ明示的に PATH に足す: export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
fi

# home-manager / nix profile を Homebrew より優先させる
export PATH="$HOME/.nix-profile/bin:$PATH"

# GCP (SDK がインストールされている場合のみ)
if [ -d "$HOME/google-cloud-sdk/bin" ]; then
  export PATH="$PATH:$HOME/google-cloud-sdk/bin"
fi
