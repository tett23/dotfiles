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
    in {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        inherit system;

        modules = [
          ({ pkgs, ... }: {
            nixpkgs.overlays = [ claude-code.overlays.default ];
            nixpkgs.config.allowUnfree = true;

            system.stateVersion = 5;
            system.primaryUser = username;
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
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
                "docker"
                "ghostty"
                "claude"
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
            home-manager.users.${username} = { pkgs, ... }: {
              home.username = username;
              home.homeDirectory = homeDirectory;
              home.stateVersion = "24.05";

              # 恒久的にインストールする CLI (dependencies.md)
              home.packages = [
                pkgs.claude-code
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
              ];

              programs.home-manager.enable = true;
            };
          }
        ];
      };
    };
}
