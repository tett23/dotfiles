# LANG・EDITOR・XDG_*・MISE_TRUSTED_CONFIG_PATHS は、非対話のシェルにも届くよう zshenv で設定する (docs/adr/0055)
# man のページを bat で色付きにする (col -bx で man の太字・下線の制御文字を外してから渡す。docs/adr/0053)
(( $+commands[bat] )) && export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# PATH の重複エントリを除去 (tmux などのネストシェルで際限なく増えるのを防ぐ)
typeset -U path PATH

# Nix の環境 (PATH・NIX_PROFILES・NIX_SSL_CERT_FILE) は nix-darwin の /etc/zshenv が設定する。
# nix-daemon.sh は NIX_PROFILES を不完全な値で上書きし、tmux の中のシェルで補完が見つからなくなるので
# 読み込まない (docs/adr/0020)

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$DOTFILES/bin"
# ghcup で入れた ghc・cabal・HLS など。~/.ghcup/env は PATH の先頭に入れるので読まず、末尾に足す (docs/adr/0050)
[ -d "$HOME/.ghcup/bin" ] && export PATH="$PATH:$HOME/.ghcup/bin"
# bun でグローバルに入れたコマンド (bun pm bin -g)。XDG_CACHE_HOME があると bun はその下の .bun を使う (docs/adr/0071)
[ -d "${XDG_CACHE_HOME:-$HOME/.cache}/.bun/bin" ] && export PATH="$PATH:${XDG_CACHE_HOME:-$HOME/.cache}/.bun/bin"

# Homebrew は使わない (Nix と mise に統一。docs/adr/0012)

# PATH の優先順位: mise (言語・ツール。zshrc の mise activate で先頭に入る) → ~/.local/bin・~/bin →
# home-manager (/etc/profiles/per-user) → Nix 本体 → システム。後ろ 3 つは nix-darwin の /etc/zshenv が設定する
# (単体の home-manager は廃止したので ~/.nix-profile/bin は足さない。docs/adr/0023)
