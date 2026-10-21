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

      # dotfiles の置き場所。リンクはここの実体を直接指す (docs/adr/0015)
      dotfilesDirectory = "${homeDirectory}/dotfiles";

      # CLI 群 (dependencies.md) と dotfiles のリンク。nix-darwin の home-manager で使う
      homeModule = { pkgs, config, lib, ... }:
        let
          # dotfiles の実体へのリンク。リポジトリの編集がすぐ反映される (docs/adr/0015)
          link = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDirectory}/${path}";
        in
        {
        # home.username・home.homeDirectory は、home-manager の nix-darwin モジュールが users.users から設定する (docs/adr/0046)
        home.stateVersion = "24.05";

        # dotfiles のリンク (旧 setup/install.sh。docs/adr/0015)
        home.file = {
          # zsh は ~/.zshenv で ZDOTDIR (~/.config/zsh) を決めるので、これだけはホーム直下に置く (docs/adr/0042)
          ".zshenv".source = link "zsh/zshenv";
          ".claude/settings.json".source = link ".claude/settings.json";
          ".claude/CLAUDE.md".source = link ".claude/CLAUDE.md";
          "Library/Application Support/Code/User/settings.json".source = link "vscode/settings.json";
          "Library/Application Support/Code/User/keybindings.json".source = link "vscode/keybindings.json";
          "Library/Application Support/Code/User/snippets".source = link "vscode/snippets";
          "Library/Application Support/AquaSKK/keymap.conf".source = link "skk/keymap.conf";
        };
        xdg.configFile = {
          # git・tmux・zsh・rubocop は XDG の場所の設定を読む (docs/adr/0042)
          "git/config".source = link "git/config";
          "git/ignore".source = link "git/ignore";
          "tmux/tmux.conf".source = link "tmux/tmux.conf";
          "zsh/.zshrc".source = link "zsh/zshrc";
          "zsh/.zshrc.mine".source = link "zsh/zshrc.mine"; # zshrc と分けておきたい設定 (docs/adr/0043)
          "rubocop/config.yml".source = link "rubocop/config.yml";
          "nvim".source = link "nvim";
          "karabiner".source = link "karabiner";
          "bat/config".source = link "bat/config";
          "ghostty/config".source = link "ghostty/config";
          "mise/config.toml".source = link "mise/config.toml";
          # tmux-nova は Nix で入れる (docs/adr/0029)。nova.tmux は自分の置き場所から scripts/ を読むため、
          # ファイル単体ではなくディレクトリをリンクする
          "tmux/plugins/tmux-nova".source = "${pkgs.tmuxPlugins.tmux-nova}/share/tmux-plugins/tmux-nova";
        };
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
          # bat-extras のうち、ripgrep・git の差分を bat で出すものだけ (docs/adr/0057)
          pkgs.bat-extras.batgrep
          pkgs.bat-extras.batdiff
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
          pkgs.smartmontools # ストレージの SMART の情報を読む smartctl (docs/adr/0075)
        ];

        # Docker のエンジンは colima を常駐させて使う (Docker Desktop から移行。docs/adr/0012)
        services.colima.enable = true;

        programs.home-manager.enable = true;
      };
    in {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        # system は nixpkgs.pkgs (aarch64-darwin で作った pkgs) から決まるので渡さない (docs/adr/0046)
        modules = [
          ({ lib, ... }: {
            nixpkgs.pkgs = pkgs;

            system.stateVersion = 5;
            # 適用したコミット (darwin-version で見られる。未コミットの変更があれば dirty の印が付く。docs/adr/0046)
            system.configurationRevision = self.rev or self.dirtyRev or null;
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
              home = homeDirectory;
            };

            # GUI アプリ (dependencies.md)。/Applications/Nix Apps に置かれる (docs/adr/0012)
            environment.systemPackages = [
              pkgs.ghostty-bin
              pkgs.vscode
              claude-desktop
            ];
              pkgs.inkscape # nixpkgs にビルド済みの Inkscape.app がある (docs/adr/0072)

            # 入力メソッドは実体のファイルとして /Library/Input Methods に置く必要がある (docs/adr/0012)。
            # 初めて入れたときはログアウトが必要
            # ほかのモジュール (home-manager の適用など) の postActivation と並べて連結する。
            # 従来どおり先に実行するよう mkBefore にする (docs/adr/0046)
            system.activationScripts.postActivation.text = lib.mkBefore ''
              echo "installing AquaSKK to /Library/Input Methods..." >&2
              ${pkgs.rsync}/bin/rsync -a --delete --chmod=u+w \
                "${aquaskk}/Library/Input Methods/AquaSKK.app/" "/Library/Input Methods/AquaSKK.app/"
            '';
          })

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # 既存のファイルやリンクと衝突したら、上書きせず .hm-backup を付けて退避する (docs/adr/0015)
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.${username} = homeModule;
          }
        ];
      };
    };
}
