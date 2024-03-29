export LANGUAGE=ja_JP
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
export RSENSE_HOME=$HOME/lib/rsense-0.3
export EDITOR=nvim
export BUNDLER_EDITOR=nvim
export PYTHONPATH=/usr/local/lib/python2.6/site-packages/
export TMUX_POWERLINE_DIR_HOME=$DOTFILES/tmux/tmux-powerline
export CABAL_BIN=$HOME/.cabal/bin
export PATH=/sbin:/usr/sbin:/opt/homebrew/bin:/usr/local/bin:$HOME/local/bin:$PATH:$CABAL_BIN
export PATH=$PATH:/home/tett23/local/bin:/home/tett23/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/bin/X11:/usr/games
export PATH=$PATH:~/Library/Python/3.6/bin
export PATH=$PATH//usr/local/sbin
export PATH=$PATH:$HOME/.local/bin
export GOROOT=/usr/local/opt/go/libexec
export GOPATH=$HOME/repositories
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export PATH=$PATH:/opt/homebrew/bin
export PATH=$PATH:$HOME/dotfiles/shellcommands

export PATH=/opt/homebrew/opt/openssl@3/bin:$PATH
export PATH=/opt/homebrew/opt/llvm@13/bin:$PATH

export LD_LIBRARY_PATH=/opt/homebrew/lib:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=/opt/homebrew/lib:$DYLD_LIBRARY_PATH
export DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib:$DYLD_FALLBACK_LIBRARY_PATH
export LDFLAGS="$LDFLAGS -L/usr/local/opt/zlib/lib"
export CPPFLAGS="$CPPFLAGS -I/usr/local/opt/zlib/include"
export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/usr/local/opt/zlib/lib/pkgconfig"

# rust
if [[ -x `which rustc` ]]; then
  export PATH="$HOME/.cargo/bin:$PATH"
  export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"
  export LD_LIBRARY_PATH=$(rustc --print sysroot)/lib:$LD_LIBRARY_PATH
  export DYLD_LIBRARY_PATH=$(rustc --print sysroot)/lib:$DYLD_LIBRARY_PATH
  export LC_RPATH=$LD_LIBRARY_PATH:$LC_RPATH
fi

export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache

# fzf
export FZF_DEFAULT_OPTS="--ansi --extended --cycle"
export FZF_DEFAULT_COMMAND='ag -g ""'

# GCP
export PATH=$PATH:$HOME/google-cloud-sdk/bin/

export LESS='--RAW-CONTROL-CHARS -R --tabs=2'
export LESSOPEN="| $DOTFILES/zsh/src-hilite-lesspipe.sh %s"
