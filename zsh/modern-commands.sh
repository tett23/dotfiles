if command -v fd >/dev/null 2>&1; then
  alias nfind="$(command -v find)"
  alias find="fd"
fi

if command -v exa >/dev/null 2>&1; then
  alias nls="$(command -v ls)"
  alias ls="exa"
fi

if command -v bat >/dev/null 2>&1; then
  alias ncat="$(command -v cat)"
  alias cat="bat"
  export BAT_PAGER="less -R"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

if command -v rg >/dev/null 2>&1; then
  alias ngrep="$(command -v grep)"
  alias grep="rg"
fi

if command -v duf >/dev/null 2>&1; then
  alias ndf="$(command -v df)"
  alias df="duf"
fi

if command -v broot >/dev/null 2>&1; then
  alias ntree="$(command -v tree)"
  alias tree="broot"
  source /Users/tett23/.config/broot/launcher/bash/br
fi
