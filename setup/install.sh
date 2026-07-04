if [ -z "$DOTFILES" ]; then
  export DOTFILES=$HOME/dotfiles
fi

if [ -z "$XDG_CONFIG_HOME" ]; then
  export XDG_CONFIG_HOME=$HOME/.config
fi
mkdir -p $XDG_CONFIG_HOME

ln -nsf $DOTFILES/nvim $XDG_CONFIG_HOME/nvim
mkdir -p $HOME/.vimbackup

ln -nsf $DOTFILES/zshenv $HOME/.zshenv
ln -nsf $DOTFILES/zsh/zshrc $HOME/.zshrc
ln -nsf $DOTFILES/gitconfig $HOME/.gitconfig
ln -nsf $DOTFILES/gitignore_global $HOME/.gitignore_global
ln -nsf $DOTFILES/tmux/tmux.conf $HOME/.tmux.conf
ln -nsf $DOTFILES/exenv $HOME/.exenv
ln -nsf $DOTFILES/rubocop.yml $HOME/.rubocop.yml

ln -nsf $DOTFILES/vscode/settings.json "$HOME/Library/Application Support/Code/User/settings.json"
ln -nsf $DOTFILES/vscode/keybindings.json "$HOME/Library/Application Support/Code/User/keybindings.json"
ln -nsf $DOTFILES/vscode/snippets "$HOME/Library/Application Support/Code/User/snippets"

ln -nsf $DOTFILES/karabiner $XDG_CONFIG_HOME/karabiner

mkdir -p $XDG_CONFIG_HOME/bat
ln -nsf $DOTFILES/bat-config $XDG_CONFIG_HOME/bat/config

mkdir -p $XDG_CONFIG_HOME/ghostty
ln -nsf $DOTFILES/ghostty/config $XDG_CONFIG_HOME/ghostty/config

# mise のグローバル設定 (言語/ツールのバージョン定義)
mkdir -p $XDG_CONFIG_HOME/mise
ln -nsf $DOTFILES/mise/config.toml $XDG_CONFIG_HOME/mise/config.toml

mkdir -p "$HOME/Library/Application Support/AquaSKK"
ln -nsf $DOTFILES/skk/keymap.conf "$HOME/Library/Application Support/AquaSKK/keymap.conf"

ln -nsf $DOTFILES/eskk $XDG_CONFIG_HOME/eskk

# Claude Code の設定ファイル (実行時データ projects/ sessions/ 等は対象外)
mkdir -p $HOME/.claude
ln -nsf $DOTFILES/claude/settings.json $HOME/.claude/settings.json
