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
fi

if command -v rg >/dev/null 2>&1; then
  alias ngrep="$(command -v grep)"
  alias grep="rg"
fi
