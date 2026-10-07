{
  description = "tett23 dotfiles: nix-darwin + home-manager (aarch64-darwin)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";  # LnL7/nix-darwin から移転 (docs/adr/0014)
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      # nixpkgs を二重に持たないよう自分の nixpkgs にそろえる (docs/adr/0014)
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, claude-code }:
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

      # nixpkgs に無いため自前で作るパッケージ (docs/adr/0012)
      claude-desktop = pkgs.callPackage ./nix/pkgs/claude-desktop.nix { };
      aquaskk = pkgs.callPackage ./nix/pkgs/aquaskk.nix { };

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
          pkgs.delta   # git pager (gitconfig で使用)
          pkgs.wget
          pkgs.tree-sitter  # nvim-treesitter (main) のパーサービルドに必要
          pkgs.docker          # docker CLI (エンジンは colima)
          pkgs.docker-compose  # docker compose
        ];

        # Docker のエンジンは colima を常駐させて使う (Docker Desktop から移行。docs/adr/0012)
        services.colima.enable = true;

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
            programs.zsh = {
              enable = true;
              # 以下は自分の .zshrc が同等の処理をするので、/etc/zshrc では行わない (docs/adr/0011)。
              # 補完ファイルの配置 (enableCompletion) は残す
              enableGlobalCompInit = false;
              enableBashCompletion = false;
              promptInit = "";
            };

            # システムユーザー定義 (home-manager が home ディレクトリを参照する)
            users.users.${username} = {
              name = username;
              home = homeDirectory;
            };

            # GUI アプリ (dependencies.md)。/Applications/Nix Apps に置かれる (docs/adr/0012)
            environment.systemPackages = [
              pkgs.ghostty-bin
              pkgs.vscode
              claude-desktop
            ];

            # 入力メソッドは実体のファイルとして /Library/Input Methods に置く必要がある (docs/adr/0012)。
            # 初めて入れたときはログアウトが必要
            system.activationScripts.postActivation.text = ''
              echo "installing AquaSKK to /Library/Input Methods..." >&2
              ${pkgs.rsync}/bin/rsync -a --delete --chmod=u+w \
                "${aquaskk}/Library/Input Methods/AquaSKK.app/" "/Library/Input Methods/AquaSKK.app/"
            '';
          })

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
