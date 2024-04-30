export LANGUAGE=ja_JP
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
export EDITOR=nvim
export BUNDLER_EDITOR=nvim

export TMUX_POWERLINE_DIR_HOME=$DOTFILES/tmux/tmux-powerline

export PATH=""
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

if test "$(uname -s)" = "Darwin" ; then
  export PATH="/opt/homebrew/bin:$PATH"
  export PATH="/opt/homebrew/sbin:$PATH"
  export PATH="/opt/homebrew/opt:$PATH"

  export LD_LIBRARY_PATH=/opt/homebrew/lib:$LD_LIBRARY_PATH;
  export LD_LIBRARY_PATH=/opt/homebrew/opt:$LD_LIBRARY_PATH;
  export DYLD_LIBRARY_PATH=/opt/homebrew/lib:$DYLD_LIBRARY_PATH;
  export DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib:$DYLD_FALLBACK_LIBRARY_PATH;
  export LIBRARY_PATH=$LIBRARY_PATH:$(brew --prefix zstd)/lib

  export LDFLAGS="$LDFLAGS -L/usr/local/opt/openssl@3/lib"
  export CPPFLAGS="$CPPFLAGS -I/usr/local/opt/openssl@3/include"

  export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
  export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
  export PATH="/opt/homebrew/opt/gawk/libexec/gnubin:$PATH"
  export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
fi

# rust
if [[ -d "$HOME/.cargo" ]]; then
  export PATH="$HOME/.cargo/bin:$PATH"
  export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"
  export LD_LIBRARY_PATH=$(rustc --print sysroot)/lib:$LD_LIBRARY_PATH
  export DYLD_LIBRARY_PATH=$(rustc --print sysroot)/lib:$DYLD_LIBRARY_PATH
  export LC_RPATH=$LD_LIBRARY_PATH:$LC_RPATH
fi

export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache

# go
if [[ -x `which go` ]]; then
  export GOPATH=$HOME/repositories
  export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
  export PATH=$PATH:$HOME/dotfiles/shellcommands
fi

# fzf
export FZF_DEFAULT_OPTS="--ansi --extended --cycle"
export FZF_DEFAULT_COMMAND='ag -g ""'

# GCP
if [[ -x `which gcloud` ]]; then
  export PATH=$PATH:$HOME/google-cloud-sdk/bin/
fi

export LESS='--RAW-CONTROL-CHARS -R --tabs=2'
export LESSOPEN="| $DOTFILES/zsh/src-hilite-lesspipe.sh %s"

## load user .zshrc configuration file
[ -f ~/.zshrc.mine ] && source ~/.zshrc.mine

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

if [[ -x `which bat` ]]; then
  export BAT_THEME='Monokai Extended Origin'
fi
