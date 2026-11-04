# 3 秒以上かかったコマンドの後に、かかった時間を出す (zsh-command-time の既定の動きの書き直し。docs/adr/0083)

# 秒を 0h:00m:05s の形にする
command_time_format() {
  local -i s=$1
  printf '%dh:%02dm:%02ds' $(( s / 3600 )) $(( s % 3600 / 60 )) $(( s % 60 ))
}

# コマンドを実行する直前に、開始の時刻を覚える
_command_time_preexec() {
  typeset -g _command_time_start=$SECONDS
}

# プロンプトを出す直前に、端末で 3 秒以上かかっていれば出し、覚えた時刻を消す
_command_time_precmd() {
  [[ -n ${_command_time_start-} ]] || return 0
  local -i elapsed=$(( SECONDS - _command_time_start ))
  unset _command_time_start
  if [[ -n ${TTY-} ]] && (( elapsed >= 3 )); then
    print -P "%F{white}Time: $(command_time_format $elapsed)%f"
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _command_time_preexec
add-zsh-hook precmd _command_time_precmd
