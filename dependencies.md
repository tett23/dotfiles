# Nix common dependencies

Nix flakes で依存を管理します。home-manager で永続化してください。
system aarch64-darwin で生成してください。
hostname は dione にしてください。
Homebrew は使いません。パッケージ管理は Nix と mise だけで行います。

## Install CLIs

以下のコマンドをインストールしてください。
sed, awk, make は GNU のものを利用してください。

claude-code codex-cli git curl fzf ghq tmux nvim direnv jq eza bat fd rg mise awscli sed awk make sqlite gh textlint delta wget tree-sitter docker docker-compose colima

- tree-sitter は nvim-treesitter (main ブランチ) がパーサーのビルドに使います。
- docker のエンジンは colima を home-manager のサービス (services.colima) として常駐させてください。
  docker と docker-compose は CLI として入れます。

## Install GUI apps

以下のアプリケーションを nix-darwin の environment.systemPackages でインストールしてください。
/Applications/Nix Apps に置かれます。

aquaskk ghostty claude vscode

- ghostty は darwin 向けの ghostty-bin を使ってください。
- aquaskk (AquaSKK) と claude (Claude デスクトップ) は nixpkgs に無いので、下記「自前パッケージ」に従って作ってください。

## 自前パッケージ

nixpkgs に無いアプリは nix/pkgs/<名前>.nix に自前のパッケージを作ってください。

- 取得元の version / url / sha256 は nix/pkgs/sources.json に書き、.nix はそれを読み込むだけにします。
  最新版は Homebrew の公開 API (https://formulae.brew.sh/api/cask/<cask 名>.json) から調べます
  (Homebrew 本体は使いません)。bin/update-nix がこの JSON を更新します。
- アプリのコード署名を壊さないよう、展開したものを加工せずに置いてください (fixup をしない)。
- claude: 配布 zip (cask 名 claude) を展開した Claude.app を置きます。
- aquaskk: 配布 pkg (cask 名 aquaskk) の Payload を展開した AquaSKK.app を置きます。
  入力メソッドは実体のファイルとして /Library/Input Methods に置く必要があるので、
  nix-darwin のアクティベーションで /Library/Input Methods/AquaSKK.app へコピーしてください。

## システム設定

- zsh は nix-darwin で有効にしますが、/etc/zshrc では compinit、bashcompinit、プロンプトテーマの読み込みを
  行わないでください (dotfiles の .zshrc が行います)。補完ファイルの配置 (enableCompletion) は残します。
- unfree なパッケージ (vscode など) を許可してください。

## 管理しないもの

- Karabiner-Elements はカーネル拡張と権限設定が絡むため、Nix では入れず手動で管理します。

# mise languages and tools dependencies

mise を使って以下の依存を管理してください。ここで指定する言語とツールは全てグローバルインストールします。
バージョンは全て latest にしてください。

## Install languages

node python ruby go rust deno bun haskell

## Install tools

yarn pnpm shfmt biome
