# セキュリティの監査 (2026-11-16)

- 日付: 2026-11-16
- 読んだコミット: `e911506386d04a2f05d2a5c64d60e30ce861c5fc`
- 範囲: リポジトリ全体
- 使ったモデル: Fable (Claude Code の `auditor`)
- 指定した推論の強さ: 指定なし
- `auditor` が報告した推論の強さ: 分からない
- 手順: `security-audit` スキル (docs/adr/0126)。[ADR 0126](../adr/0126-audit-skill.md) の受けいれ条件 A4 の試しの監査を兼ねる。

以下は `auditor` が返した指摘を、変えずに貼ったものである。

---

推論の強さ (effort): 分からない (自分からは設定値を読めない)。
読んだコミット: e911506386d04a2f05d2a5c64d60e30ce861c5fc (`git rev-parse HEAD`、作業ツリーは clean)。範囲: リポジトリ全体 (追跡 285 ファイル、履歴は `git log --all`)。コードとファイルは変えていない (確かめは `$TMPDIR` の使い捨てリポジトリで行った)。

## 指摘
1. [外から来る入力 / 中] `/Users/tett23/dotfiles/bin/orch` の `cleanup`・`wait`・`collect` が `--role` を検証しない。検証は `spawn` だけ (bin/orch:111)。`cleanup_role` (bin/orch:281-296) は `rm -rf "$ORCH_DIR/worktrees/$role"` (292) と `rm -rf "$rdir"` (295) を行う。確かめ: 使い捨てリポジトリで `orch init` の後 `orch cleanup --role ../../../outside` → `orch: cleaned ../../../outside` exit=0、リポジトリの外の `outside/` が消えた。呼び手は LLM の司令塔なので、role の値ひとつでリポジトリの外を消せる。
2. [権限 / 中] `/Users/tett23/dotfiles/bin/sync-deps --switch` は、`claude -p` が書いた `flake.nix` などを、内容を人が読む前に root で適用する。`--permission-mode acceptEdits` (86)、差分の表示は `--stat` だけ (116)、差分があればそのまま `sudo darwin-rebuild switch` (126-134, 161-162)。flake の `system.activationScripts` は root で動く (flake.nix:208-212)。止まるのは sudo のパスワードだけ。
3. [依存の固定 / 中] `/Users/tett23/dotfiles/mise/config.toml:5-30` は全ツールが `"latest"` で、ロックファイルもハッシュも無い (`git ls-files | grep -i lock` → flake.lock と nvim/lazy-lock.json だけ)。GitHub リリースのバイナリ (`github:tett23/adr-guard`、`github:bootandy/dust` など) と npm (`npm:prh`、`npm:typescript`) を含む。`adr-guard` は Write/Edit のたびの hook (.claude/settings.json:12、codex/hooks.json:9) と pre-commit (.githooks/pre-commit:9) で動き、`prh` も hook で動くので、リリースや npm のアカウントが侵されると、次の `mise install`/`update-mise` でそのまま実行される。
4. [依存の固定 / 低] `/Users/tett23/dotfiles/bin/update-nix:41-48,60-62` は URL と sha256 を同じ応答 (formulae.brew.sh) から取り、URL のホストを確かめずに `sources.json` に書く。同じ実行でビルドし `sudo` で適用する (96-100)。AquaSKK は root で `/Library/Input Methods` に rsync される (flake.nix:210-211)。ハッシュは取得元と独立した検証になっていない。`nix flake update` で個人リポジトリの入力 `sadjow/claude-code-nix` (flake.nix:15) も同時に進む。
5. [権限 / 低] `bin/sync-deps:28-44` の許可: `Read Edit Write` にパスの限定が無い。`Bash(nix store prefetch-file:*)`・`Bash(nix-prefetch-url:*)` は任意の URL に届くので、37 行目の「curl の前方一致の許可は広すぎる」という意図と食い違う。`Bash(nix eval:*)`・`Bash(nix build:*)` も任意の式を受ける。入力 (dependencies.md、nix search や formulae.brew.sh の応答) からの注入があると、読んだ内容を URL に載せて出せる。sandbox で止まるかは未確認 (下)。
6. [依存の固定 / 低] CI の action がタグ参照で、コミット SHA で固定していない: `.github/workflows/ci.yml:26,39,57,74` (`actions/checkout@v7`)、63 (`tett23/adr-guard@v0.13.1`)、76 (`DeterminateSystems/determinate-nix-action@v3`)。`bootstrap.sh:57-58` は版を固定した URL を `curl | sh` するがハッシュを確かめない。`README.md:6` の `install.sh` は `HEAD` から `curl | sh`。
7. [依存の固定 / 低] `zsh/plugins.sh:7,13-18`: zinit を版なしで clone し、固定コミットへの checkout が失敗しても警告だけで `source` する (fail-open)。`nvim/lua/config/lazy.lua:6` は lazy.nvim を `--branch=stable` で取得、`nvim/lua/plugins/lsp.lua:42` の mason の `ensure_installed` は版の固定なし。
8. [秘密の情報 / 低] `bin/budget-check:140` は一覧の「計測のコマンド」を `sh -c "$cmd"` で動かし、環境をそのまま渡す。CI の例 (agents/skills/conformance-audit/SKILL.md:63-78) では `GH_TOKEN` (`issues: write`) が計測のコマンドにも見える。例にトリガーの指定が無い。
9. [権限 / 低] 「コードを変えない」が指示だけで、設定では強制されていない。`.claude/agents/auditor.md:5` は `tools: Read, Grep, Glob, Bash`。`rg -n 'sandbox|approval' codex/` は 0 件 (codex/agents/*.toml に `sandbox_mode` 無し)。`.claude/settings.json:37-39` は `sandbox.enabled: true` だけで、`permissions.deny` も読み取りの拒否パスも無い (この実行の sandbox の read は Claude 内部のパスだけを拒否する denyOnly、write は `.` を許可)。
10. [秘密の情報 / 低] 履歴の個人情報。`git log --all --format='%ae%n%ce' | sort | uniq -c` で、gmail 以外の 2 つの勤務先らしいドメインのアドレスが 26 件と 20 件。削除済みの `open_gh.sh` (1d5f187 で削除) に他組織のリポジトリ名が残る。公開リポジトリの履歴から読める。

## 問題が見つからなかったこと
- 秘密の混入: 作業ツリーと履歴 (`git log --all -p -G` で ghp_/github_pat_/sk-/AKIA/xox/AIza/PRIVATE KEY/password・token の代入) は該当なし。出たのは空の `TMUX_POWERLINE_SEG_MAILCOUNT_GMAIL_PASSWORD=""` (ee4663a ほか) と SKILL.md:78 の `${{ github.token }}` だけ。`.env`・鍵・`hosts.yml` の名前のファイルは履歴に無い。gh の `hosts.yml` は管理外 (flake.nix:104)。
- 追跡外の `.claude/settings.local.json` (gitignore 済み): allow 38 件は狭いコマンドと Read で、deny 無し、秘密なし。
- flake.lock: 5 入力すべて rev と narHash あり (jq で確認)。`nix/pkgs/sources.json` は sha256 つき。zinit のプラグインは `ver` でコミット固定、`nvim/lazy-lock.json` は 37 件。
- CI: `permissions: contents: read` (ci.yml:13-14)、`pull_request_target` と `secrets.` の参照なし。
- `bin/prh-claude-hook`: パスは引用して渡し、`eval` なし、`mktemp -d` と trap で片付ける。`.md` の通常ファイルだけ読む。
- 権限ビット: `find . -perm -002` は 0 件。実行ビットはスクリプト 18 本だけ。`core.hooksPath` は `.githooks`。
- tmux の OSC 7 (`zsh/lib/tmux-osc7.zsh:10,17` で制御文字を除く)、`@cwd` は `-c` にだけ使う (tmux/tmux.conf:55-57,78)。`usage-hint` は認証の handle を api.anthropic.com にだけ渡し、保存するのは rateLimits だけ (register.tsx:77-105)。

## 未確認
- gitleaks・trufflehog は未導入 (`command -v` で無し)。履歴はパターン検索だけで、エントロピーの検査はしていない。削除済み 1204 ファイル (多くは atom/packages) は中身を個別に読んでいない。
- 指摘 5: 実際の `claude -p` で、sandbox が `nix-prefetch-url` の任意ホストへの通信を止めるかは動かしていない。
- 指摘 9: sandbox の中から `~/.ssh` などが実際に読めるかは、対象外の認証情報に触れるので試していない。`~/.codex/config.toml` (管理外) の sandbox・承認の設定も読んでいない。
- `adr-guard` のバイナリの中身、hook で `adr-guard` が無いときの振る舞い (fail-open か) は確かめていない。
- GitHub 側の設定 (secret scanning、ブランチ保護、Actions の権限の既定) は確かめていない。
