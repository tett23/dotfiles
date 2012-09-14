source $BYOBU_PREFIX/share/byobu/profiles/tmux

iset-option -g status on
set-option -g status-interval 2
set-option -g status-utf8 on
set-option -g status-justify "centre"
set-option -g status-left-length 60
set-option -g status-right-length 90
set-option -g status-left "#(~/.tmux/tmux-powerline/status-left.sh)"
set-option -g status-right "#(~/.tmux/tmux-powerline/status-right.sh)"

source ~/path/to/tmux-colors-solarized/tmuxcolors.conf
