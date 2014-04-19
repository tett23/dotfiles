#source $BYOBU_PREFIX/share/byobu/profiles/tmux

set-option -g status on
set-option -g status-interval 2
set-option -g status-utf8 on
set-option -g status-justify "centre"
set-option -g status-left-length 100
set-option -g status-right-length 100
set-option -g status-left "#(~/dotfiles/tmux/tmux-powerline/powerline.sh left)"
set-option -g status-right "#(~/dotfiles/tmux/tmux-powerline/powerline.sh right)"

set -g default-terminal "screen-256color"
set -g status-bg colour237

set-option -g terminal-overrides "*88col*:colors=88,*256col*:colors=256"
set -g terminal-overrides "xterm*:kLFT5=\eOD:kRIT5=\eOC:kUP5=\eOA:kDN5=\eOB:smkx@:rmkx@:colors=256"
set-option -g default-terminal "xterm"

set-option -g default-shell /bin/zsh

set -sg escape-time 0
