export PATH="$HOME/.pyenv:$PATH"
if which pyenv > /dev/null; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/shims:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi


# volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# rbenv
if command -v rbenv 1>/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi
