# ADR 違反と予算違反の監査 (2026-11-16)

- 日付: 2026-11-16
- 読んだコミット: `e911506386d04a2f05d2a5c64d60e30ce861c5fc`
- 範囲: リポジトリ全体。ADR 違反は [ADR 0110](../adr/0110-tmux-directory-name-while-pipeline-runs.md)〜0129 を重点に見た。
- 使ったモデル: Fable (Claude Code の `auditor`)
- 指定した推論の強さ: 指定なし
- `auditor` が報告した推論の強さ: 分からない
- 手順: `conformance-audit` スキル (docs/adr/0126)。[ADR 0126](../adr/0126-audit-skill.md) の受けいれ条件 A4 の試しの監査を兼ねる。

以下は `auditor` が返した指摘を、変えずに貼ったものである。

---

推論の強さ (effort): 分からない (自分の設定値を確かめる手段が無い)。
読んだコミット: e911506386d04a2f05d2a5c64d60e30ce861c5fc (`git rev-parse HEAD`、作業ツリーは clean)。範囲: リポジトリ全体。ADR 違反は [ADR 0110](../adr/0110-tmux-directory-name-while-pipeline-runs.md)〜0129 を重点に見た (`adr-guard list --status` で 0117 と 0118 が `superseded [...]`、ほかは `accepted`)。ファイルは変えていない。

## ADR 違反の指摘

1. 観点: 実装しないこと / 重大度: 高
   - 根拠: /Users/tett23/dotfiles/docs/adr/0115-codex-adr-guard-hook.md:47「Codex の hook で、ほかの検査 (prh など) を動かすこと」(実装しないこと)。`jq -c . codex/hooks.json` は `"PostToolUse":[{"matcher":"^(apply_patch|Bash)$","hooks":[{"type":"command","command":"${DOTFILES:-$HOME/dotfiles}/bin/prh-claude-hook"}]}]` を含む。docs/specifications.md:293 もこれを書く。
   - 問題: コミット 91e3814 (`Run the prh hook after Codex patches as well`) が ADR なしで入れた。`rg -n "PostToolUse|codex/hooks.json" docs/adr` に、これを決めた ADR は無い。[ADR 0115](../adr/0115-codex-adr-guard-hook.md) は `accepted` のままである。

2. 観点: 不変条件 ([ADR 0128](../adr/0128-budget-check-in-ci.md) I10) / 重大度: 中
   - 根拠: /Users/tett23/dotfiles/bin/budget-check:185 が `awk -v re="$num_re"` で正規表現を渡し、`\.` が `.` になる (stderr に `awk: warning: escape sequence '\.' treated as plain '.'`)。[ADR 0128](../adr/0128-budget-check-in-ci.md):57 と :112 は、数でない印を読み飛ばすとする。
   - 動かしたこと: スクラッチの git リポジトリと偽の `gh` で、`<= 100`、計測 120、本文の印 `value=130 state=violation`、新しいコメントの印 `value=9x9 state=violation`。期待はコメントなし (130 より 120 はよい)。実際は `gh issue comment 5` が呼ばれ、本文に `- 前の値: 9x9 (差: +111)`。gawk 5.4.1 と `/usr/bin/awk` の両方で同じ。
   - 問題: 正しくない印を前の記録として読む。今あるテスト (`ADR 0128 I10: いちばん新しい印が壊れていれば…`) はこの入力を持たない。

3. 観点: 不変条件 ([ADR 0128](../adr/0128-budget-check-in-ci.md) I6、I8) / 重大度: 中
   - 根拠: /Users/tett23/dotfiles/bin/budget-check:236 (`check_budget "$2" … "$7"`) と :13 (`set -u`)。[ADR 0128](../adr/0128-budget-check-in-ci.md):45 は、エラーにする行をセルの数が 6 でない行と名前が重なる行だけとし、:108 は、ほかの予算の確かめを続けるとする。
   - 動かしたこと: 1 行目 `| a | ms | <= | 1 | \`echo 2\` | |` (ADR のセルが空、セルは 6 つ)、2 行目は違反の予算。出力 `budget-check: 行 236: $7: 未割り当ての変数です`、`rc=1`、偽の `gh` の呼び出しは 0 回。
   - 問題: 末尾のセルが空の行でスクリプト全体が止まり、後の違反の予算に issue を作らない。

4. 観点: 実装しないこと、仕様書 / 重大度: 中
   - 根拠: [ADR 0116](../adr/0116-remove-example-skills-plugin.md):34「`lua-lsp` を外すこと」(実装しないこと)、docs/specifications.md:262「有効にするプラグインは `lua-lsp` だけにする」。`jq -c .enabledPlugins .claude/settings.json` は `{"lua-lsp@claude-plugins-official":false}` (.claude/settings.json:34)。
   - 問題: コミット 2f84621 (`Reorder the Claude Code settings as the app writes them`) が `true` を `false` に変えた。有効なプラグインは 0 個で、ADR と仕様書に合わない。

5. 観点: 実装すること (元の ADR のステータス) / 重大度: 中
   - 根拠: agents/skills/adr/SKILL.md:13「修正用の ADR が採択されたら、元の ADR のステータスを `superseded [...]` にする」。次の ADR は、後の ADR が中身を変えたのに `accepted` か、その変更が配列に無い。
     - [ADR 0114](../adr/0114-codex-agents-md.md):34 (「モデルの使い分け」を書かない)、:45-46 (hook と使い分けを書かない)。[ADR 0115](../adr/0115-codex-adr-guard-hook.md) と 0117 が変えた (codex/hooks.json、codex/AGENTS.md:112)。0114 は `accepted`。
     - [ADR 0122](../adr/0122-move-adr-rules-into-skill.md):37-41 と A1 (:61)「ADR の節は 3 つだけ」。[ADR 0127](../adr/0127-skills-table-in-shared-instructions.md):37 が `adr` の一文を消した (.claude/CLAUDE.md:26-33 は 2 つ)。0122 は `accepted`。
     - [ADR 0123](../adr/0123-context-restore-skill.md):37 と A2 (:57)「ai-chat-log の節が 2 行」。[ADR 0127](../adr/0127-skills-table-in-shared-instructions.md) の後は 1 行 (.claude/CLAUDE.md:84-86)。0123 は `accepted`。
     - [ADR 0118](../adr/0118-split-instructions-into-skills.md):47 (スキルを読む一行を置く) を 0127 が、[ADR 0117](../adr/0117-codex-model-roles.md):49 と 0111:29 (使い分けにエージェントを書く) を 0118:48 が変えた。0118 と 0117 の配列にその記録が無く、0111 は `accepted`。
   - 問題: `accepted` の文面どおりに読むと実装と合わない。`adr-guard trace` でも修正の連なりをたどれない。

6. 観点: 受けいれ条件 ([ADR 0126](../adr/0126-audit-skill.md) A4) / 重大度: 低
   - 根拠: [ADR 0126](../adr/0126-audit-skill.md):113「`docs/audits/` に二つの記録ができる」。`ls docs/audits | rg -c "security-audit|conformance-audit"` は 0 件。
   - 問題: A4 の試しの監査の記録が無いまま、ステータスが `accepted` である。

7. 観点: 実装すること ([ADR 0128](../adr/0128-budget-check-in-ci.md) の 10、12) / 重大度: 低
   - bin/budget-check:184 は `<!-- … -->` の枠を見ない ([ADR 0128](../adr/0128-budget-check-in-ci.md):57 は枠つきの形だけを正しい印とする)。コメントが `引用: budget-check: value=500 state=violation と書いた` だけのとき、期待は違反のコメントを足すことだが、実際は書き込みの `gh` が呼ばれない。
   - 前の記録が `state=ok` のとき、コメントは `- 前の記録: 90 ok` で、差を書かない (bin/budget-check:196-200。[ADR 0128](../adr/0128-budget-check-in-ci.md):71「前の記録があれば前の値との差」)。

8. 観点: 受けいれ条件 ([ADR 0129](../adr/0129-standard-docs-layout.md) A1) / 重大度: 低
   - 根拠: [ADR 0129](../adr/0129-standard-docs-layout.md):55-56 と .claude/CLAUDE.md:53、:130。CI の決まりに、ADR に無い「ただし、ビルドやテストの入力になるファイルの変更では省かない」と「(モノレポの…を含む)」がある。「GitHub actions」の文は、ADR の「標準の構成の `docs/` のパス (`docs/budgets.md` を除く) の中だけの変更では省く」でなく「…は、「docs/ の構成」の決まりに従う」である。
   - 問題: A1 の「表と決まりが一字も違わずに」を ADR の文との一致と読むと合わない。表は一致し、両ファイルの節どうしは `diff` で差が無い。

## 問題が無かった項目

- zsh のテスト: `zsh zsh/tests/*.test.zsh` の 12 本がすべて `all passed`。`fzf-history-preview` と `window-switcher` は sandbox の中で `mktemp` が失敗したので、sandbox の外で動かし直して通った。
- [ADR 0128](../adr/0128-budget-check-in-ci.md): I1〜I12 のすべてに `ADR 0128 I<n>:` で始まるテストがあり通る (45 件 PASS)。shellcheck の一覧 (.github/workflows/ci.yml:31)、仕様書 (:275-278)、スキルの記述がある。dotfiles の CI に予算のジョブは無い (:97 のとおり)。リポジトリの外のパスは `rc=1`。
- [ADR 0129](../adr/0129-standard-docs-layout.md): `docs/audit` は無い。`git show -M --name-status 1c7f758` は R100 が 9 件、M が 18 件、トレーラー `ADR-Guard-Allow: dotfiles ADR 0129`。`audits/20` は 21 か所、古いパスは 0 件。`adr-guard links` は rc=0。adr スキル :75 に `.gitkeep` の手順。
- [ADR 0127](../adr/0127-skills-table-in-shared-instructions.md): A3 の `grep -cF` は消した 4 句が 0 件、残した 2 句が 1 件ずつ。「スキル」の節は両ファイルで差が無い。仕様書 :266、:269。
- [ADR 0126](../adr/0126-audit-skill.md): `codex/agents/auditor.toml:5` は `"medium"`。二つの `auditor` の説明がスキルを指す。二つのスキルの共通の決まりの差は、記録のファイル名と予算の一文だけ。`.claude/agents/auditor.md` に effort は無い。`docs/budgets.md` は無い。
- [ADR 0124](../adr/0124-invariant-and-test-naming.md)、[0125](../adr/0125-roadmap-skill.md): 0122 と 0123 の A 番号と、af4da61 のトレーラー。0125〜0129 の受けいれ条件はすべて、テスト設計に同じ番号の手順を持つ。`roadmap` スキルと flake.nix のリンク (:66-81) がある。
- [ADR 0110](../adr/0110-tmux-directory-name-while-pipeline-runs.md)〜0113、0119〜0121: tmux の `@cwd` と `@cwd-name` (tmux/tmux.conf:35-78)、3 つのエージェントの `model` と `tools`、`gh/config.yml`、`services.colima` の値、`bashOutputMaxChars` 10000、`pkgs.elan` (flake.nix:145) と dependencies.md の 1 件、`adr-guard@v0.13.1`、`adr-guard check-status` と `check-numbers` が rc=0、旧形式のステータスの行は 0 件。
- README: [ADR 0110](../adr/0110-tmux-directory-name-while-pipeline-runs.md)〜0129 はどれも README を変えないとしており、README の adr-guard の手順 (:27-30) は今の設定と合う。

## 未実装の一覧

なし (`adr-guard list --status | grep -i pending` は 0 件)。

## 予算違反

予算なし。`docs/budgets.md` は無く、[ADR 0110](../adr/0110-tmux-directory-name-while-pipeline-runs.md)〜0129 の受けいれ条件に性能の予算は無い ([ADR 0128](../adr/0128-budget-check-in-ci.md):97「dotfiles には予算が無い」)。[ADR 0001](../adr/0001-curl-sh-install.md)〜0109 の受けいれ条件は読んでいない。

## 未確認

- CI の結果 ([ADR 0128](../adr/0128-budget-check-in-ci.md) A1、0129 A4、0121 の `adr` ジョブ): `gh run list --commit e911506…` が sandbox の中で `tls: failed to verify certificate` で失敗した。shellcheck は手元に無く、動かしていない。
- ubuntu の CI の awk (mawk) で、指摘 2 が同じく起きるか。
- `darwin-rebuild switch` の後の手での確かめ ([ADR 0111](../adr/0111-claude-agents-in-dotfiles.md)〜0115、0117、0118、0122、0123、0125、0126 A3 の新しいセッションのスキルやエージェントの一覧、colima、gh、Codex の hook)。`~/.claude/skills` と `~/.agents/skills` に 8 つのリンクがあることだけ見た。[ADR 0112](../adr/0112-gh-config-in-dotfiles.md):46 と 0113:77 は、確かめを「まだ行っていない」と書いたまま `accepted` である。
- `nix flake check`、`nix build` ([ADR 0120](../adr/0120-elan.md) のテスト設計) は動かしていない。
- [ADR 0001](../adr/0001-curl-sh-install.md)〜0109 は、ステータスの一覧のほかは読んでいない。
