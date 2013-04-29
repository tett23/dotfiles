
set-option -g prefix C-j
unbind-key -n C-a

bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

bind p previous-window
bind n next-window

bind s split-window -v
bind v split-window -h

setw -g mode-keys vi
unbind-key -n C-j
set -g prefix ^J
set -g prefix2 ^J
bind j send-prefix
