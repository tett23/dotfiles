{
  description = "tett23 dotfiles: nix-darwin + home-manager (aarch64-darwin)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew, claude-code }:
    let
      system = "aarch64-darwin";
      username = "tett23";
      homeDirectory = "/Users/tett23";
      hostname = "dione";

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ claude-code.overlays.default ];
        config.allowUnfree = true;
      };

      # CLI 群 (dependencies.md)。darwin / standalone 両方で共有
      homeModule = { pkgs, ... }: {
        home.username = username;
        home.homeDirectory = homeDirectory;
        home.stateVersion = "24.05";

        home.packages = [
          pkgs.claude-code
          pkgs.codex   # codex-cli
          pkgs.git
          pkgs.curl
          pkgs.fzf
          pkgs.ghq
          pkgs.tmux
          pkgs.neovim
          pkgs.direnv
          pkgs.jq
          pkgs.eza
          pkgs.bat
          pkgs.fd
          pkgs.ripgrep  # rg
          pkgs.mise
          pkgs.awscli2  # awscli
          pkgs.gnused   # GNU sed
          pkgs.gawk     # GNU awk
          pkgs.gnumake  # GNU make
          pkgs.sqlite
          pkgs.gh
          pkgs.textlint
        ];

        programs.home-manager.enable = true;
      };
    in {
      # sudo 不要: `home-manager switch --flake .#tett23`
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ homeModule ];
      };

      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        inherit system;

        modules = [
          ({ ... }: {
            nixpkgs.pkgs = pkgs;

            system.stateVersion = 5;
            system.primaryUser = username;
            # Determinate Nix が Nix 本体を管理するため nix-darwin 側の管理は無効化
            # (flakes/experimental-features は Determinate 側で有効化済み)
            nix.enable = false;
            programs.zsh.enable = true;

            # システムユーザー定義 (home-manager が home ディレクトリを参照する)
            users.users.${username} = {
              name = username;
              home = homeDirectory;
            };

            # GUI アプリは nix-darwin の Homebrew モジュールで管理 (Casks)
            homebrew = {
              enable = true;
              onActivation.cleanup = "zap";
              casks = [
                "aquaskk"
                "docker-desktop"  # 旧 "docker" cask からリネーム
                "ghostty"
                "claude"
                "codex"
              ];
            };
          })

          # Homebrew 本体のインストール自体も宣言的に管理
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              user = username;
              enableRosetta = false;  # Apple Silicon ネイティブのみ
              autoMigrate = true;     # 既存 Homebrew があれば引き継ぐ
            };
          }

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = homeModule;
          }
        ];
      };
    };
}
