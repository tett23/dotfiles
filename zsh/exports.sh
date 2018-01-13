export LANGUAGE=ja_JP
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
export RSENSE_HOME=$HOME/lib/rsense-0.3
export EDITOR=vim
export BUNDLER_EDITOR=vim
export PYTHONPATH=/usr/local/lib/python2.6/site-packages/
export TMUX_POWERLINE_DIR_HOME=$DOTFILES/tmux/tmux-powerline
export CABAL_BIN=$HOME/.cabal/bin
export PATH=/sbin:/usr/sbin:/usr/local/bin:$HOME/local/bin:$PATH:$CABAL_BIN
export PATH=$PATH:/home/tett23/local/bin:/home/tett23/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/bin/X11:/usr/games
export PATH=$PATH:~/Library/Python/3.6/bin
export ZSH=$HOME/.oh-my-zsh
export GOROOT=/usr/local/opt/go/libexec
export GOPATH=$HOME/projects/golang
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export ZSH=$HOME/.oh-my-zsh

# rust
export PATH="$HOME/.cargo/bin:$PATH"
export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"
export LD_LIBRARY_PATH=$(rustc --print sysroot)/lib:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=$(rustc --print sysroot)/lib:$DYLD_LIBRARY_PATH
export LC_RPATH=$LD_LIBRARY_PATH:$LC_RPATH

export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache

export PYENV_ROOT=/usr/local/opt/pyenv
export PATH=$DOTFILES/exenv/bin:$PATH

plugins=(git)
#exec $SHELL
echo 'eval "$(exenv init -)"' >> ~/.bash_profile
