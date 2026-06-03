{
  description = "Claude Code via sadjow/claude-code-nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs = { self, nixpkgs, home-manager, claude-code }:
    let
      system = "aarch64-darwin";
      username = "tett23";
      homeDirectory = "/Users/tett23";

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ claude-code.overlays.default ];
        config.allowUnfree = true;
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.claude-code ];
      };

      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          {
            home.username = username;
            home.homeDirectory = homeDirectory;
            home.stateVersion = "24.05";

            # 恒久的にインストールするパッケージ
            home.packages = [
              pkgs.claude-code
              # 常用ツールをここに追加していく
              # pkgs.git
              # pkgs.ripgrep
            ];

            programs.home-manager.enable = true;
          }
        ];
      };
    };
}
