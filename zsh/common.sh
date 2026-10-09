# auto change directory
#
setopt auto_cd

# auto directory pushd that you can get dirs list by cd -[tab]
#
setopt auto_pushd

# command correct edition before each completion attempt
#
setopt correct

# compacked complete list display
#
setopt list_packed

# no remove postfix slash of command line
#
setopt noautoremoveslash

# no beep sound when complete list displayed
#
setopt nolistbeep

## Keybind configuration
#
# vim like keybind
#
# vim/nvim 内の :terminal では vi キーバインドにしない
if [[ ! -v VIMRUNTIME ]]; then
  bindkey -v
fi

# historical backward/forward search with linehead string binded to ^P/^N
#
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "\\ep" history-beginning-search-backward-end
bindkey "\\en" history-beginning-search-forward-end

## Command history configuration
#
# 履歴は XDG の場所に置く。旧 ~/.zsh_history があれば移す (docs/adr/0023)
HISTFILE=${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history
if [[ ! -e $HISTFILE ]]; then
  mkdir -p ${HISTFILE:h}
  [[ -f $HOME/.zsh_history ]] && mv $HOME/.zsh_history $HISTFILE
fi
HISTSIZE=500000
SAVEHIST=500000
setopt hist_ignore_dups # ignore duplication command history list
setopt share_history # share command history data
setopt hist_ignore_space # 先頭が空白のコマンドは履歴に残さない
setopt hist_reduce_blanks # 余分な空白を詰めて記録する
setopt extended_history # 実行時刻と所要時間も記録する (share_history との併用が推奨。docs/adr/0010)

## Alias configuration
#
# expand aliases before completing
#
setopt complete_aliases # aliased ls needs if file/dir completions work

setopt no_beep
