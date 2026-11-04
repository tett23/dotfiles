# tmux の中で、今のディレクトリを OSC 7 で Ghostty に知らせる (docs/adr/0085)。
# tmux は OSC 7 を Ghostty に渡さないので、passthrough (allow-passthrough on) で包んで送る。
# Ghostty は、これを元に相対パスのリンクを開く。tmux の外では Ghostty のシェルインテグレーションが送る

# OSC 7 (kitty-shell-cwd://<ホスト><パス>。パスを符号化せずに送れる) を passthrough で包む。
# 中の ESC は 2 つ重ねる。ホストとパスの制御文字は取り除く (Ghostty のシェルインテグレーションと同じ)
tmux_osc7_sequence() {
  local host=${1//[[:cntrl:]]} dir=${2//[[:cntrl:]]}
  print -rn -- $'\ePtmux;\e\e]7;kitty-shell-cwd://'"$host$dir"$'\a\e\\'
}

# 書き込み先 (テストで差し替える)
typeset -g _tmux_osc7_out=${_tmux_osc7_out:-/dev/tty}

_tmux_osc7_report() {
  [[ -n ${TMUX-} ]] || return 0
  tmux_osc7_sequence "$HOST" "$PWD" >>| $_tmux_osc7_out 2>/dev/null
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _tmux_osc7_report
add-zsh-hook chpwd _tmux_osc7_report
