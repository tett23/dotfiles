# python
if [ -d "$PYENV_ROOT" ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  export PATH="$PYENV_ROOT/shims:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# volta
if [ -d "$HOME/.volta" ]; then
  export VOLTA_HOME="$HOME/.volta"
  export PATH="$VOLTA_HOME/bin:$PATH"
fi

# rbenv
if [ -d "$HOME/.rbenv" ]; then
  eval "$(rbenv init -)"
fi

# haskell
if [ -d "$HOME/.ghcup" ]; then
  source $HOME/.ghcup/env
fi
