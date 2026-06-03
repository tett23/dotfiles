{
  description = "Claude Code via sadjow/claude-code-nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs = { self, nixpkgs, claude-code }:
    let
      system = "aarch64-darwin";  # Apple Silicon Mac の場合
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ claude-code.overlays.default ];
        config.allowUnfree = true;
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.claude-code ];
      };
    };
}
