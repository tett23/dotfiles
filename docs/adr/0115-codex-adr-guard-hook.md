# ADR 0115: Codex の hook で adr-guard を動かし、hooks.json を dotfiles で管理する

ステータス: 採択

## 文脈

[ADR 0114](0114-codex-agents-md.md) は、Codex の hook (`hooks.json`) で adr-guard を動かすことを、実装しないことにした。
当時の adr-guard に、Codex 用の hook が無かったためである。
そのため、`codex/AGENTS.md` には「Codex には adr-guard の hook が無い」と書いてある。

その後、adr-guard の v0.11.0 (2026-11-10) で、Codex の PreToolUse hook 用の `adr-guard codex-hook [--allow-status]` が加わった (tett23/adr-guard の [ADR 0021](https://github.com/tett23/adr-guard/blob/v0.11.0/docs/adr/0021-codex-hook.md))。
`codex-hook` は、Codex がファイルの編集に使う `apply_patch` のパッチを読み、コミット済みの ADR と記録を変える・消す・移すパッチを終了コード 2 で止める。

確かめたことは次のとおり。

- adr-guard の側で、`codex-cli 0.166.0` の一時リポジトリに `.codex/hooks.json` を置いて `codex exec` を動かした。ADR の本文を書きかえるパッチは hook が止め、ステータスの行だけを変えるパッチは通った (tett23/adr-guard#23 のコメント)。
- Codex は、全体の hook を `~/.codex/hooks.json` から読む (openai/codex `rust-v0.166.0` の `codex-rs/hooks/src/engine/discovery.rs`)。いまの `~/.codex/hooks.json` は無い (`cat ~/.codex/hooks.json` が「No such file or directory」)。
- Codex は、新しく足した hook と、変えた hook を、本人が対話の画面の `/hooks` で信頼するまで動かさない。信頼していない hook では、ADR の本文を書きかえるパッチがそのまま当たった (adr-guard の側の確認)。信頼の状態は `~/.codex/config.toml` に書かれる。
- 手元の adr-guard は mise の `"github:tett23/adr-guard" = "latest"` で入れている。いまは 0.10.0 で、0.11.0 は mise の `minimum_release_age` (24 時間) で隠されている (`mise upgrade github:tett23/adr-guard` の警告)。0.10.0 には `codex-hook` が無く、終了コード 64 で終わる。Codex は終了コード 0 と 2 以外を hook の失敗として扱い、編集を止めない。
- Claude Code の hook は、`.claude/settings.json` の `adr-guard claude-hook --allow-status` で有効にしている ([ADR 0030](0030-claude-config-in-dot-claude.md))。

## 実装すること

- `codex/hooks.json` を作り、PreToolUse の hook として `adr-guard codex-hook --allow-status` を、`matcher` を `^(apply_patch|Bash)$` として呼ぶ。`Bash` は、シェルのコマンドの中のパッチを調べるために含める。

  ```json
  {
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "^(apply_patch|Bash)$",
          "hooks": [{ "type": "command", "command": "adr-guard codex-hook --allow-status" }]
        }
      ]
    }
  }
  ```

- `flake.nix` の `home.file` に `".codex/hooks.json".source = link "codex/hooks.json";` を足す。
- `codex/AGENTS.md` の「Codex には adr-guard の hook が無い。…」の文を、`.claude/CLAUDE.md` に合わせて「Codex の hook は全体の設定 (`~/.codex/hooks.json`) で有効なので不要」に変える。`.claude/CLAUDE.md` は変えない。
- `docs/specifications.md` のリンクの表に `~/.codex/hooks.json` を、Codex の節に hook のことを書く。

## 実装しないこと

- `~/.codex/config.toml` を dotfiles で管理すること ([ADR 0114](0114-codex-agents-md.md) と同じ理由)。hook の信頼の状態もここに書かれるので、本人が `/hooks` で信頼する。
- mise の `minimum_release_age` を adr-guard で外すこと。0.11.0 は、制限が過ぎた後の `mise upgrade` で入る。それまでの hook は失敗として扱われ、編集を止めない。
- Codex の hook で、ほかの検査 (prh など) を動かすこと。

## テスト設計

設定の変更なので、CI の自動テストは書かない。実装の後に次を確かめる。

- `jq . codex/hooks.json` が通る。
- `nix flake check --no-build` が通る。
- 本人が `sudo darwin-rebuild switch --flake ~/dotfiles#dione` を実行した後:
  - `ls -l ~/.codex/hooks.json` が、dotfiles の `codex/hooks.json` を指すリンクになる。
  - adr-guard が 0.11.0 になった後 (`adr-guard -V`)、本人が Codex の `/hooks` でこの hook を信頼し、コミット済みの ADR がある dotfiles で、ADR の本文の書きかえを Codex に頼むと、hook が止める。

## 結果

- `jq . codex/hooks.json` は通った。`nix flake check --no-build` も通った。
- 実装の前は `~/.codex/hooks.json` が無かった。本人の頼みで、switch を待たずに `ln -s ~/dotfiles/codex/hooks.json ~/.codex/hooks.json` でリンクを作った。switch のときは、home-manager がこのリンクを `hooks.json.hm-backup` に退かし、自分のリンクに置きかえる。
- 手元の adr-guard は 0.10.0 のままで (`adr-guard -V`)、`codex-hook` はまだ無い。Codex の `/hooks` での信頼と、ADR の書きかえを止める確かめは、0.11.0 が入った後に本人が行う。

## トレードオフ

- 0.11.0 が入るまでの約 24 時間は、hook が毎回失敗として記録される。編集は止めないので、作業は妨げない。
- `matcher` に `Bash` を含めるので、Codex のシェルのコマンドのたびに adr-guard が起動する。パッチを含まないコマンドでは JSON を読むだけで終わる。
- `codex-hook` はパッチの消す行と足す行で判定するので、本文に触れるパッチは中身が変わらなくても止める。`sed -i` などパッチ以外のコマンドによる変更は止めず、pre-commit hook と CI の `adr` ジョブが止める。

## 参考文献

- tett23/adr-guard の [ADR 0021](https://github.com/tett23/adr-guard/blob/v0.11.0/docs/adr/0021-codex-hook.md)、[v0.11.0](https://github.com/tett23/adr-guard/releases/tag/v0.11.0)、[tett23/adr-guard#23](https://github.com/tett23/adr-guard/pull/23)
- openai/codex のタグ `rust-v0.166.0` の `codex-rs/hooks/src/engine/discovery.rs`
- dotfiles の [ADR 0030](0030-claude-config-in-dot-claude.md)、[ADR 0114](0114-codex-agents-md.md)
