if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

export PATH=$DOTFILES/exenv/bin:$PATH
echo 'eval "$(exenv init -)"' >> ~/.bash_profile

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
source ~/.rvm/scripts/rvm

# volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
