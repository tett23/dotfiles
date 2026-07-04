export LANGUAGE=ja_JP
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
export EDITOR=nvim

export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_RUNTIME_DIR=$HOME/.local/run
export XDG_STATE_HOME=$HOME/.local/state

# Nix
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# mise: dotfiles 実体へ symlink した設定を無条件に信頼する (別マシンでの `mise trust` を不要にする)
export MISE_TRUSTED_CONFIG_PATHS="$HOME/dotfiles/mise:$HOME/.config/mise"

export PATH="/bin:$PATH"
export PATH="/sbin:$PATH"
export PATH="/usr/bin:$PATH"
export PATH="/usr/sbin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/sbin:$PATH"
export PATH="$HOME/usr/bin:$PATH"
export PATH="$HOME/usr/sbin:$PATH"
export PATH="$HOME/usr/local/bin:$PATH"
export PATH="$HOME/usr/local/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

export PATH="$PATH:$DOTFILES/bin"
export PATH="$PATH:$HOME/dotfiles/shellcommands"

if test "$(uname -s)" = "Darwin" ; then
  export PATH="/opt/homebrew/bin:$PATH"
  export PATH="/opt/homebrew/sbin:$PATH"
  export PATH="/opt/homebrew/opt:$PATH"

  # export LD_LIBRARY_PATH=/opt/homebrew/lib:$LD_LIBRARY_PATH;
  # export LD_LIBRARY_PATH=/opt/homebrew/opt:$LD_LIBRARY_PATH;
  # export DYLD_LIBRARY_PATH=/opt/homebrew/lib:$DYLD_LIBRARY_PATH;
  # export DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib:$DYLD_FALLBACK_LIBRARY_PATH;
  # export LIBRARY_PATH=$LIBRARY_PATH:$(brew --prefix zstd)/lib

  # Apple Silicon の homebrew prefix を使う (旧: /usr/local は Intel 用で存在しない)
  export LDFLAGS="$LDFLAGS -L/opt/homebrew/opt/openssl@3/lib"
  export CPPFLAGS="$CPPFLAGS -I/opt/homebrew/opt/openssl@3/include"

  export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
  # NOTE: homebrew LLVM の clang を PATH 先頭に置くと -lSystem を解決できずビルドが壊れるため無効化。
  # 必要なときだけ明示的に PATH に足す: export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
  export PATH="/opt/homebrew/opt/gawk/libexec/gnubin:$PATH"
  export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
fi

# home-manager / nix profile を Homebrew より優先させる
export PATH="$HOME/.nix-profile/bin:$PATH"

# GCP
if [[ -x `which gcloud` ]]; then
  export PATH=$PATH:$HOME/google-cloud-sdk/bin/
fi
