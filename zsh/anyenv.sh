if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

# volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# rbenv
eval "$(rbenv init - zsh)"
