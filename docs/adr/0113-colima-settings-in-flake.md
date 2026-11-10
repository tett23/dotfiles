# ADR 0113: colima の既定のプロファイルの設定を flake.nix に書く

ステータス: 採択

## 文脈

本人から、グローバルの設定のうち symlink になっていないものを挙げ、dotfiles に入れたほうがよいものを ADR にするよう頼まれた。
Docker のエンジンは colima で、`flake.nix` の `services.colima.enable = true;` で常駐させている ([ADR 0012](0012-remove-homebrew.md))。しかし、VM の設定 (CPU、メモリ、ディスク) は dotfiles に無い。

調べたことは次のとおり。

- home-manager (`b787c48`) の `modules/services/colima.nix`:
  - `services.colima.profiles` を書かないと、`default` のプロファイル (`isActive = true`、`isService = true`) だけになる。
    `profiles` を書くと既定の値は置き換わり、各項目の既定は `isActive = false`・`isService = false`・`setDockerHost = false` になる。
  - `settings` を書くと、`<colimaHomeDir>/<プロファイル>/colima.yaml` を Nix ストアのファイルへのリンクにする (`mutableSettings = false` のとき)。
    launchd のエージェントは `colima start <プロファイル> -f --save-config=false` になり、colima は設定を書き戻さない。
  - `settings` が空のときは `--save-config=true` で、colima が `colima.yaml` を自分で書く。今はこの形である。
  - `colimaHomeDir` は、`home.stateVersion` が `26.05` より前なら `.colima`。dotfiles は `24.05` なので `~/.colima` である。
- `~/.colima/default/colima.yaml` は普通のファイルで、colima の既定の値のままである (`cpu: 2`、`memory: 2`、`disk: 100`、`runtime: docker`、`vmType: vz`、`mountType: virtiofs` など)。
- `colima list` の結果:

  | プロファイル | 状態 | CPU | メモリ | ディスク |
  | --- | --- | --- | --- | --- |
  | `default` | Running | 2 | 2GiB | 100GiB |
  | `golemplug` | Running | 4 | 8GiB | 60GiB |

  `golemplug` は dotfiles の外で作ったプロファイルで、launchd のエージェントは無い。
- `flake.nix` の `home-manager.backupFileExtension` は `hm-backup` なので、home-manager がリンクを置く場所に普通のファイルがあると、`colima.yaml.hm-backup` に退かす。

## 実装すること

- `flake.nix` の `services.colima` に、既定のプロファイルを書く。値は今の `colima list` と `colima.yaml` に合わせ、VM の作りは変えない。

  ```nix
  services.colima = {
    enable = true;
    # profiles を書くと既定の値が置き換わるので、isActive と isService も書く (docs/adr/0113)
    profiles.default = {
      isActive = true;
      isService = true;
      settings = {
        cpu = 2;
        memory = 2;
        disk = 100;
        runtime = "docker";
        vmType = "vz";
        mountType = "virtiofs";
      };
    };
  };
  ```

- `docs/specifications.md` の Docker の記述に、VM の設定を `flake.nix` に書くことを足す。README は変えない。

## 実装しないこと

- `golemplug` のプロファイルを管理すること。Golem の作業のために dotfiles の外で作ったもので、常駐させていない。
- `colimaHomeDir` を `~/.config/colima` に移すこと (`home.stateVersion` を上げる必要があり、ほかの既定も変わる)。
- `mutableSettings = true` にすること。colima が書き戻した値と `flake.nix` の値が混ざり、どちらが正しいかわからなくなる。
- CPU やメモリの値を変えること。

## テスト設計

設定の変更なので、CI の自動テストは書かない。実装の前に次を実行して今の値を確かめ、本人が `sudo darwin-rebuild switch --flake ~/dotfiles#dione` を実行した後に、もう一度実行して確かめる。

- `ls -l ~/.colima/default/colima.yaml`: 実装の前は普通のファイル、実装の後は Nix ストアのファイルへのリンクになり、`colima.yaml.hm-backup` ができる。
- `colima list` の `default` が、実装の前と同じ CPU・メモリ・ディスクで `Running` になる。`golemplug` は変わらない。
- `launchctl print gui/$(id -u)/org.nix-community.home.colima-default` の引数に `--save-config=false` が入る。
- `docker run --rm hello-world` が通る。

## 結果

- 実装の前: `~/.colima/default/colima.yaml` は普通のファイル (8462 バイト)。`colima list` は「文脈」の表のとおり。launchd のエージェントの引数は `colima start default -f --activate=true --save-config=true`。
- `nix flake check --no-build` は通った。評価した結果:
  - launchd のエージェントの引数は `colima start default -f --activate=true --save-config=false` になった。
  - `home.file.".colima/default/colima.yaml"` は、`cpu: 2`・`disk: 100`・`memory: 2`・`mountType: virtiofs`・`runtime: docker`・`vmType: vz` の YAML になった。
- 本人が `darwin-rebuild switch` を実行した後の確かめ (「テスト設計」の残り) は、まだ行っていない。

## トレードオフ

- `darwin-rebuild switch` で launchd のエージェントの引数が変わるので、`default` の VM が起動し直すことがある。動いているコンテナは止まる。
- `colima start --cpu 4` のように手で値を変えても、`colima.yaml` は読み取り専用なので書き戻されない。値を変えるときは `flake.nix` を書きかえる。
- `settings` に書かない項目は colima の既定の値になる。colima の版を上げて既定が変わると、その項目も変わる。

## 参考文献

- home-manager (`b787c48`) の `modules/services/colima.nix`
- colima の既定の設定: https://github.com/abiosoft/colima/blob/main/embedded/defaults/colima.yaml
- `colima list`、`~/.colima/default/colima.yaml`
- dotfiles の `flake.nix`、[ADR 0012](0012-remove-homebrew.md)
