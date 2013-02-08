#source $BYOBU_PREFIX/share/byobu/profiles/tmux

iset-option -g status on
set-option -g status-interval 2
set-option -g status-utf8 on
set-option -g status-justify "centre"
set-option -g status-left-length 60
set-option -g status-right-length 90
set-option -g status-left "#(~/.tmux/tmux-powerline/status-left.sh)"
set-option -g status-right "#(~/.tmux/tmux-powerline/status-right.sh)"

set-option -g terminal-overrides "*88col*:colors=88,*256col*:colors=256"
set -g terminal-overrides "xterm*:kLFT5=\eOD:kRIT5=\eOC:kUP5=\eOA:kDN5=\eOB:smkx@:rmkx@:colors=256"
set-option -g default-terminal "screen-256color"

source ~/.tmux/tmux-colors-solarized/tmuxcolors-256.conf

set -sg escape-time 0
