# ADR 0112: gh の設定 `config.yml` を dotfiles で管理する

ステータス: 採択

## 文脈

本人から、グローバルの設定のうち symlink になっていないものを挙げ、dotfiles に入れたほうがよいものを ADR にするよう頼まれた。
gh (GitHub CLI) は `dependencies.md` の CLI にあり、`flake.nix` の `home.packages` の `pkgs.gh` で入れている。しかし、その設定は dotfiles で管理していない。

調べたことは次のとおり。

- `~/.config/gh/` には、`config.yml` (1661 バイト、2026-07-23 更新) と `hosts.yml` (78 バイト) の 2 つがある。どちらも symlink でなく、権限は `600` である。
- `config.yml` の中身は、gh が書いた既定の注釈と値に加えて、自分で決めた値が 2 つある: `git_protocol: https` と、エイリアスの `co: pr checkout`。
  トークンや利用者名は入っていない。
- `hosts.yml` は、ログインしたホストと利用者を持つ。gh の認証情報に関わるので、dotfiles に入れない。
- dotfiles の XDG の場所の設定は、`flake.nix` の `xdg.configFile` で `link` (`mkOutOfStoreSymlink`) を使い、dotfiles の実体にリンクしている
  ([ADR 0015](0015-fix-breaking-audit-items.md)、[ADR 0042](0042-xdg-config-locations.md))。
- `gh config set` と `gh alias set` は `config.yml` を書き換える。dotfiles の実体へのリンクであれば、書き換えは dotfiles のファイルに入る (NablaSKK の設定と同じ形。[ADR 0081](0081-nablaskk-config-in-dotfiles.md))。

## 実装すること

- 今の `~/.config/gh/config.yml` を dotfiles の `gh/config.yml` に移す。中身は変えない。
- `flake.nix` の `xdg.configFile` に `"gh/config.yml".source = link "gh/config.yml";` を足し、注釈に、`hosts.yml` は認証情報を持つので管理しないことと、この ADR を書く。
- `docs/specifications.md` のリンクの表に書く。README は変えない。

## 実装しないこと

- `~/.config/gh/hosts.yml` を管理すること。
- home-manager の `programs.gh` を使うこと。`programs.gh` は `config.yml` を Nix ストアの読み取り専用のファイルにするので、`gh config set` と `gh alias set` が書き込めなくなる。
- `config.yml` の値を変えること。

## テスト設計

設定の変更なので、CI の自動テストは書かない。実装の前に次を実行して今の値を確かめ、本人が `sudo darwin-rebuild switch --flake ~/dotfiles#dione` を実行した後に、もう一度実行して確かめる。

- `ls -l ~/.config/gh/config.yml`: 実装の前は普通のファイル、実装の後は dotfiles の `gh/config.yml` を指すリンクになる。
- `gh config get git_protocol` が `https` になる。
- `gh alias list` に `co: pr checkout` が出る。
- `gh auth status` が、実装の前と同じくログインしている状態を出す (`hosts.yml` を壊していない)。

## 結果

- 実装の前: `~/.config/gh/config.yml` は普通のファイル (`-rw-------`、1661 バイト)。`gh config get git_protocol` は `https`、`gh alias list` は `co: pr checkout`、`gh auth status` は `Logged in to github.com account tett23 (keyring)`。
- `~/.config/gh/config.yml` を dotfiles の `gh/config.yml` に写した (権限は 644 にした)。元のファイルは、switch のときに home-manager が `config.yml.hm-backup` に退かす。
- `nix flake check --no-build` は通った。`xdg.configFile."gh/config.yml".target` は `.config/gh/config.yml` になった。
- 本人が `darwin-rebuild switch` を実行した後の確かめ (「テスト設計」の残り) は、まだ行っていない。

## トレードオフ

- `gh config set` や `gh alias set` を実行すると、dotfiles の作業ツリーに差分が出る。コミットするかは、そのときに決める。
- `config.yml` の既定の注釈も dotfiles に入る。gh が書く形のままにしておくほうが、gh が書き換えたときの差分が小さい。

## 参考文献

- `gh help config`、`gh help alias`
- home-manager の `modules/programs/gh.nix` (`programs.gh.settings` が `config.yml` を生成する)
- dotfiles の `flake.nix`、[ADR 0015](0015-fix-breaking-audit-items.md)、[ADR 0042](0042-xdg-config-locations.md)、[ADR 0081](0081-nablaskk-config-in-dotfiles.md)
