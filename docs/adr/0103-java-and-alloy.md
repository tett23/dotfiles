# ADR 0103: Java を mise で、Alloy を Nix で入れる

ステータス: 採択

## 文脈

本人から、Java と Alloy を依存に足して入れるよう頼まれた。
Alloy (https://alloytools.org/) は、関係のモデルを書く言語と、その制約を満たす構造を探して図で見せる道具 (Alloy Analyzer) である。

調べたことは次のとおり。

- 今の手元には Java が無い。`command -v java` は macOS の `/usr/bin/java` (入っていないと知らせるだけのもの) で、
  `/usr/libexec/java_home` は「Unable to locate a Java Runtime」を返す。
- mise は Java を本体で扱う (`java`)。`mise latest java` は `27.0.1+1`。
  既定の `minimum_release_age` (24 時間) で、新しい 19 の版が隠されている ([ADR 0099](0099-nvim-peg-hs-lsp.md) と同じ)。
  mise で入れた言語は、PATH で `/usr/bin` より前に来る ([ADR 0023](0023-fix-remaining-audit-items-2.md))。
- Alloy のリリース (GitHub の `AlloyTools/org.alloytools.alloy`): 最新は `v6.2.0` (2025-01-09)。
  どの環境でも動く jar (`org.alloytools.alloy.dist.jar`) と、macOS 向けの zip (`alloy-6.2.0-mac-aarch64.zip`、49 MB) がある。
- dotfiles の `flake.lock` の nixpkgs:
  - `alloy6` が 6.2.0 (最新と同じ)。上の jar を nixpkgs の `jre` (21.0.11) で動かすラッパー `bin/alloy6` を作る。`platforms` は unix で、aarch64-darwin を含む。
  - `alloy` は 5 系の `alloy5` (5.1.0) を指す。dependencies.md の名前 `alloy` と nixpkgs の名前が合わない。
- mise の登録簿に Alloy は無い (`mise ls-remote alloy` は「alloy not found in mise tool registry」を返す)。

## 実装すること

- `dependencies.md`:
  - 「Install languages」に `java` を足す。
  - 「Install CLIs」に `alloy` を足し、nixpkgs の `alloy6` を入れる (nixpkgs の `alloy` は 5 系) と書く。
- `mise/config.toml` の `[tools]` に `java = "latest"` を足す (`lua` の後)。
- `flake.nix` の `home.packages` に `pkgs.alloy6` を足す。注釈に、nixpkgs の `alloy` は 5 系であることと、この ADR を書く。
- `mise install java` と `darwin-rebuild switch` で入れる (`darwin-rebuild switch` は sudo が要るので、本人が実行する)。
- `docs/specifications.md` の「依存の管理」に書く。README は依存の一覧を dependencies.md に任せているので変えない。

## 実装しないこと

- Alloy を GitHub の macOS 向けの zip (mise の github バックエンドなど) で入れること。nixpkgs の `alloy6` が最新と同じ版で、jar を動かすだけなので、Nix で足りる。
- Alloy を mise の Java で動かすこと。nixpkgs の `alloy6` は nixpkgs の `jre` を使い、mise の Java と別に持つ。
- Alloy の編集の支援 (nvim のファイルタイプ・シンタックスハイライト・LSP)。要るときに別の ADR で足す。
- Java の LSP サーバー (jdtls) やビルドの道具 (Maven、Gradle)。

## テスト設計

依存の追加なので、CI の自動テストは書かない。実装の前に次を実行して今の値を確かめ (上の「文脈」)、実装の後にもう一度実行して確かめる。

- `command -v java` が mise の Java を指し、`java -version` が 27 系を返す。`mise ls --current java` に出る。
- `nix build .#darwinConfigurations.dione.system` が通る (`darwin-rebuild switch` の前)。
- `darwin-rebuild switch` の後、`command -v alloy6` が home-manager のプロファイルを指す。
- Alloy の jar の CLI で、小さなモデルの `run` が解を見つける (`sig A {} run {} for 3` のようなモデル。CLI の使い方は実装のときに `alloy6 --help` で確かめる)。
- 本人が確かめる: `alloy6 gui` で、Alloy Analyzer のウィンドウが開く。

## 結果

- 実装の前: `command -v java` は `/usr/bin/java`、`/usr/libexec/java_home` は「Unable to locate a Java Runtime」。`command -v alloy6` は何も返さない。`mise ls --current java` は空。
- `mise install java` の後: `command -v java` は mise の Java を指し、`java -version` は `openjdk version "27.0.1.0.2"` (Temurin-27.0.1.0.2+1)。
  `mise ls --current java` は `27.0.1+1` (`mise/config.toml` の `latest`)。mise の既定の Java の配布元は Temurin だった。
- `nix build .#darwinConfigurations.dione.system` は通った。
- nixpkgs の `alloy6` (6.2.0) の `bin/alloy6` で、`sig A {}` と `run { some A } for 3` のモデルを `alloy6 exec -o - -t text` に渡すと、`this/A={A$0}` の解を返した。`alloy6 version` は `6.2.0`。
  CLI には `gui` (ウィンドウを開く) と `lsp` (Alloy の LSP サーバー) のサブコマンドもある。
  Claude Code の sandbox の中では、ソルバーが一時ディレクトリを作れずに失敗したので、sandbox の外で動かした。
- 本人が `darwin-rebuild switch` をした後: `command -v alloy6` は `/etc/profiles/per-user/tett23/bin/alloy6`。本人が `alloy6 gui` でウィンドウが開くことを確かめた。

## トレードオフ

- Java の実行環境を 2 つ持つ (mise の Java と、Alloy のための nixpkgs の `jre`)。
- コマンドの名前は `alloy` でなく `alloy6` になる。
- `java = "latest"` は Java の新しい大きな版 (28 など) が出ると上がる。Alloy は nixpkgs の `jre` で動くので、この影響を受けない。

## 参考文献

- Alloy のサイト: https://alloytools.org/
- Alloy のリリース: https://github.com/AlloyTools/org.alloytools.alloy/releases/tag/v6.2.0
- nixpkgs の `pkgs/development/tools/alloy/default.nix` (dotfiles の `flake.lock` の版)
- mise の Java: https://mise.jdx.dev/lang/java.html
- 手元での `mise latest java`・`mise ls-remote java`・`nix eval` の結果
