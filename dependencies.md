# Nix common dependencies

Nix flakes で依存を管理します。home-manager で永続化してください。
system aarch64-darwin で生成してください。
hostname は dione にしてください。

## Install CLIs

以下のコマンドをインストールしてください。
sed, awk, make は GNU のものを利用してください。

claude-code codex-cli git curl fzf ghq tmux nvim direnv jq eza bat fd rg mise awscli sed awk make sqlite gh textlint

## Install Casks

以下のアプリケーションを nix-darwin 経由でインストールしてください

aquaskk docker ghostty claude codex

# mise languages and tools dependencies

mise を使って以下の依存を管理してください。ここで指定する言語とツールは全てグローバルインストールします。
バージョンは全て latest にしてください。

## Install languages

node python ruby go rust deno bun haskell

## Install tools

yarn pnpm shfmt biomeskill-creator
