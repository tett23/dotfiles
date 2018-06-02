# Default Theme

if patched_font_in_use; then
  TMUX_POWERLINE_SEPARATOR_LEFT_BOLD="⮂"
  TMUX_POWERLINE_SEPARATOR_LEFT_THIN="⮃"
  TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD="⮀"
  TMUX_POWERLINE_SEPARATOR_RIGHT_THIN="⮁"
else
  TMUX_POWERLINE_SEPARATOR_LEFT_BOLD="◀"
  TMUX_POWERLINE_SEPARATOR_LEFT_THIN="❮"
  TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD="▶"
  TMUX_POWERLINE_SEPARATOR_RIGHT_THIN="❯"
fi

TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR=${TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR:-'235'}
TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR=${TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR:-'255'}

TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR=${TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR:-$TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD}
TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR=${TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR:-$TMUX_POWERLINE_SEPARATOR_LEFT_BOLD}


# Format: segment_name background_color foreground_color [non_default_separator]

if [ -z $TMUX_POWERLINE_LEFT_STATUS_SEGMENTS ]; then
  TMUX_POWERLINE_LEFT_STATUS_SEGMENTS=(
    "tmux_session_info 235 136 "${TMUX_POWERLINE_SEPARATOR_RIGHT_THIN} \
    "hostname 235 167 ${TMUX_POWERLINE_SEPARATOR_RIGHT_THIN}" \
    #"ifstat 30 255" \
    #"ifstat_sys 30 255" \
    "lan_ip 235 167 ${TMUX_POWERLINE_SEPARATOR_RIGHT_THIN}" \
    #"wan_ip 182 239" \
    "vcs_branch 235 136 ${TMUX_POWERLINE_SEPARATOR_RIGHT_THIN}" \
    #"vcs_compare 235 136 ${TMUX_POWERLINE_SEPARATOR_RIGHT_THIN}" \
    #"vcs_staged 235 136" ${TMUX_POWERLINE_SEPARATOR_RIGHT_THIN} \
    "vcs_modified 235 136 ${TMUX_POWERLINE_SEPARATOR_RIGHT_THIN}" \
    #"vcs_others 235 136 ${TMUX_POWERLINE_SEPARATOR_RIGHT_THIN}" \
  )
fi

if [ -z $TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS ]; then
  TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS=(
    #"earthquake 3 0" \
    #"pwd 89 211" \
    #"mailcount 9 255" \
    #"now_playing 234 37" \
    "cpu 240 136" \
    "load 237 167" \
    #"tmux_mem_cpu_load 234 136" \
    #"battery 137 127" \
    #"weather 37 255" \
    #"rainbarf 0 0" \
    #"xkb_layout 125 117" \
    "date 235 136 ${TMUX_POWERLINE_SEPARATOR_LEFT_THIN}" \
    "time 235 136 ${TMUX_POWERLINE_SEPARATOR_LEFT_THIN}" \
    "utc_time 235 136 ${TMUX_POWERLINE_SEPARATOR_LEFT_THIN}" \
  )
fi
