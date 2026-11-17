# ADR 0140: sync-deps の claude -p に許すツールを、書き換える範囲と決まったコマンドに絞る

Status: accepted

## 文脈

`bin/sync-deps` は、`claude -p` に `dependencies.md` を読ませて、`flake.nix`、`mise/config.toml`、`nix/pkgs/` を書かせる ([ADR 0013](0013-generate-config-from-dependencies-with-claude.md))。
[ADR 0133](0133-sync-deps-confirm-before-switch.md) は、適用の前に差分の全体を見せて確認を取ると決め、`claude -p` に許すツールを絞り直すことは別の ADR に回した。

2026-11-16 のセキュリティの監査 ([docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md) の指摘 5) は、これを重大度「低」の問題として挙げた。
`claude -p` には、パスの限定の無い `Read`、`Edit`、`Write` と、任意の URL に届く `nix-prefetch-url`、`nix store prefetch-file`、任意の式を受ける `nix eval`、`nix build` を許している。
そのため、`dependencies.md` や `nix search` の応答から注入された指示に従うと、Claude は手元のファイルを読み、その中身を URL に載せて外へ出せる。
本人は、ADR を作って扱うと決めた。

そのため、この ADR で、`claude -p` の権限のモードと許すツールを、書き換える範囲と決まったコマンドに絞る。

## 調査した事項

- `bin/sync-deps` は、`cd "$DOTFILES"` の後に `claude -p "$PROMPT" … --permission-mode acceptEdits --allowedTools "${ALLOWED_TOOLS[@]}" --disallowedTools "${DISALLOWED_TOOLS[@]}"` を動かす (87〜93 行)。`ALLOWED_TOOLS` は、`Read Edit Write Glob Grep`、`Bash(nix search:*)`、`Bash(nix eval:*)`、`Bash(nix build:*)`、`Bash(nix flake lock:*)`、`Bash(nix flake show:*)`、`Bash(nix store prefetch-file:*)`、`Bash(nix-prefetch-url:*)`、`WebFetch(domain:formulae.brew.sh)`、`Bash(git diff:*)`、`Bash(git status:*)`、`Bash(git add -N:*)`、`Bash(mise ls:*)`、`Bash(mise registry:*)` である (32〜48 行)。`DISALLOWED_TOOLS` は 50〜58 行にある。
- 手元の Claude Code は `2.1.322` である (`claude --version`)。以下の文書は、`https://code.claude.com/docs/en/permissions.md`、`headless.md`、`sandboxing.md` を 2026-11-17 に取って読んだ。
  - `acceptEdits` は、作業ディレクトリの中のファイルの編集を、許可の規則によらず自動で認める (`permissions.md` の 77 行)。そのため、`acceptEdits` のままでは、`Edit` をパスで絞っても、作業ディレクトリの中の編集は止まらない。
  - `dontAsk` は、確認を求めるはずの呼び出しをすべて断る。作業ディレクトリの中のファイルの読み取りと、承認の要らない操作は動く (`permissions.md` の 80 行、`headless.md` の 328 行)。
  - `Read` と `Edit` の規則は gitignore の書き方で、`path` と `./path` は作業ディレクトリからの相対である (`permissions.md` の 368〜377 行)。
  - `Write(パス)`、`Glob(パス)`、`Grep(パス)` は、パスを付けても照合されない。代わりに `Edit` と `Read` の規則を書く (`permissions.md` の 359〜366 行)。`Edit` の規則は、ファイルを書き換える組み込みのツールすべてに効く (342 行)。
  - Bash を許すと、WebFetch を絞っても `curl` などで任意の URL に届く (`permissions.md` の 303 行)。
  - sandbox は Bash とその子のプロセスだけを囲い、組み込みの Read、Edit、Write、WebFetch は許可の規則に従う (`sandboxing.md` の 42 行)。
- `nix-prefetch-url` と `nix store prefetch-file` は、今の手順では使わない。`.claude/skills/sync-deps/SKILL.md` に `prefetch` と `sha256` の記述は無い。今ある二つの自前パッケージの `sha256` は、`bin/update-nix` が Homebrew の API から取る (`bin/update-nix` の 22〜25、41〜47 行)。ただし、スキルの 56 行は、nixpkgs に無いものを `nix/pkgs/<name>.nix` に作り、取得元を `sources.json` に書くとしている。新しい自前パッケージの `sha256` を取る手段は、prefetch を禁じると、`WebFetch(domain:formulae.brew.sh)` で読む Homebrew の cask の JSON だけになる。
- 手元の nix (`Determinate Nix 3.21.0`、`2.34.6`) で、次を確かめた。
  - `nix eval --impure --expr 'builtins.fetchurl "http://127.0.0.1:1/x"'` は、その URL に取りに行った。
  - `nix eval --impure --expr 'builtins.readFile /etc/hosts'` は、ファイルの中身を返した。
  - `nix eval --impure --expr 'builtins.exec ["echo" "hi"]'` は、`attribute 'exec' missing` で失敗した。
  - `nix show-config` は `sandbox = false` を出す。ビルドの中の任意のコマンドが、ネットワークに届くかは確かめていない (推して、届く)。
- `Bash(…)` の規則の `*` は任意の文字の並びに合い、`*` の無い規則は完全一致である。末尾の ` *` (空白と `*`) は、コマンドだけの呼び出しにも合う。`:*` は末尾の ` *` と同じ意味である (`permissions.md` の 137、186〜189 行)。完全一致の規則が、引数の足された呼び出しを実際に拒むかは、動かして確かめていない。
- `claude` には `--setting-sources <sources>` があり、読む設定を `user`、`project`、`local` から選べる (`claude --help`)。
- `claude -p` は `$DOTFILES` で動く (87 行)。そこには、`.gitignore` で除いた `.claude/settings.local.json` があり、`permissions.allow` に 38 の規則を持つ。そのうち `Read` の規則は、リポジトリの外のパスを許すものを含み、`Bash` の規則は `zsh -ic` などを含む (`jq -r '.permissions.allow[]' .claude/settings.local.json`)。設定のファイルの規則が、`--allowedTools` と合わせて効くかは、動かして確かめていない。

## 実装すること

- `claude -p` の `--permission-mode` を、`acceptEdits` から `dontAsk` にする。
- `claude -p` に `--setting-sources user` を渡し、dotfiles の `.claude/settings.json` (project) と `.claude/settings.local.json` (local) の規則を読ませない。全体の設定 (user) は、hook (adr-guard、prh) を持つので読ませる。
- `ALLOWED_TOOLS` を、次だけにする。
  - `Edit(flake.nix)`、`Edit(flake.lock)`、`Edit(mise/config.toml)`、`Edit(nix/**)`: 書き換える範囲。`Write` も、この規則で絞られる。
  - `Bash(nix search nixpkgs *)`: パッケージの名前を探す。
  - `Bash(nix build --no-link .#darwinConfigurations.dione.system)`: プロンプトが指示するビルド。
  - `Bash(nix flake lock)`: `flake.lock` を合わせる。
  - `WebFetch(domain:formulae.brew.sh)`、`Bash(git diff *)`、`Bash(git status *)`、`Bash(git add -N nix/*)`、`Bash(mise ls *)`、`Bash(mise registry *)`。
- `Read`、`Glob`、`Grep` は許可に書かない。`dontAsk` では、作業ディレクトリ (dotfiles) の中の読み取りは許可なしで動き、外の読み取りは断られる。
- `nix eval`、`nix flake show`、`nix store prefetch-file`、`nix-prefetch-url` は許さない。
- `DISALLOWED_TOOLS` は、中身を変えず、書き方を `Bash(sudo *)` のように空白と `*` にそろえる (`:*` と同じ意味である)。
- プロンプトに、使えるコマンドがこの一覧だけであることと、`nix-prefetch-url` などで `sha256` を取らないことを書く。新しい自前パッケージは、Homebrew の cask の JSON の `url` と `sha256` を使い、cask の無いものは足さずに報告に書く、と書く。
- `.claude/skills/sync-deps/SKILL.md` の `bin/sync-deps` の説明に、`claude -p` が書き換えられるのは `flake.nix`、`flake.lock`、`mise/config.toml`、`nix/` だけであることを書く。
- `docs/specifications.md` の `bin/sync-deps` の行に、同じことを書く。
- [ADR 0013](0013-generate-config-from-dependencies-with-claude.md) のステータスに、`{"part":"Decision (claude -p に許すツール)","by":["docs/adr/0140-sync-deps-narrow-claude-tools.md"],"kind":"supplement"}` を足す。0013 の「ファイルの読み書きと、読み取り・ビルド系のコマンドに絞る」は、この ADR の後も成り立ち、この ADR はその絞り方を細かく決めるためである。
- [ADR 0133](0133-sync-deps-confirm-before-switch.md) のステータスに、`{"part":"実装しないこと (claude -p に許すツールを絞り直すこと)","by":["docs/adr/0140-sync-deps-narrow-claude-tools.md"],"kind":"note","note":"別の ADR で決めるとした絞り直しを決めた"}` を足して、`superseded` にする。

## 実装しないこと

- `claude -p` を sandbox (`--settings` の `sandbox` と `network.allowedDomains`) で囲うこと。nix のビルドが Seatbelt の中で動くか、必要なホストがどれかを確かめていない。確かめてから、別の ADR で決める。
- `nix build` の中で動くコマンドを絞ること。ビルドは Claude の書いた式を動かすので、適用の前の確認 ([ADR 0133](0133-sync-deps-confirm-before-switch.md)) より前に動く。
- 許す規則を、`.claude/settings.json` に書くこと。`bin/sync-deps` の中だけで使う。

## 不変条件

- I1: `bin/sync-deps` が `claude` に渡す引数は、`--permission-mode dontAsk` と `--setting-sources user` を含み、`acceptEdits` を含まない。
- I2: `bin/sync-deps` が `claude` に渡す `--allowedTools` の値は、上の「実装すること」の一覧とちょうど一致する。

境界の入力:

| 入力 | 期待 | 不変条件 |
| --- | --- | --- |
| 偽の `claude` が受けた引数 | `--permission-mode` の次が `dontAsk`、`--setting-sources` の次が `user` | I1 |
| 偽の `claude` が受けた引数 | `--allowedTools` の値が一覧と一致し、`Read`、`Write`、`nix-prefetch-url` などを含まない | I2 |

## 受けいれ条件

- A1: `zsh/tests/sync-deps.test.zsh` の、上の不変条件の番号を持つテストが通る。dotfiles の CI の `zsh-tests` と shellcheck のジョブも通る。
- A2: 本人が、`dependencies.md` に一時的にパッケージを足して `bin/sync-deps` を動かし、Claude が `flake.nix` を書き換え、`nix build` が通ることを確かめる。`dontAsk` と規則の書き方で生成が止まらないことを、このときに確かめる。

## テスト設計

- A1: [ADR 0133](0133-sync-deps-confirm-before-switch.md) のテストの偽の `claude` に、受けた引数を一つずつ記録させ、I1 と I2 を確かめる。テストを先に書いて失敗させる。テストの名前は `ADR 0140 I1: …` の形にする。
- A2: 手で確かめる。止まったときは、止まった規則を Claude の報告から読み、この ADR を直す新しい ADR で書き方を決め直す。

## トレードオフ

- 規則の書き方が実際の呼び出しと合わないと、生成の途中で断られて止まる。そのときは、本人が規則を足すまで `bin/sync-deps` を使えない。
- `nix build` は Claude の書いた式を動かすので、ビルドの中の任意のコマンドは、この ADR では防げない。
- `git diff *` などの読み取りのコマンドは、dotfiles の外のパスを引数に取れる。
- cask の無い自前パッケージは、`bin/sync-deps` では足せない。本人が手で足す。
- `--setting-sources user` で、dotfiles の `.claude/settings.json` の設定 (sandbox など) も読まなくなる。

## 参考文献

- dotfiles の [ADR 0013](0013-generate-config-from-dependencies-with-claude.md)、[ADR 0133](0133-sync-deps-confirm-before-switch.md)
- [docs/audits/2026-11-16-security-audit.md](../audits/2026-11-16-security-audit.md)
- https://code.claude.com/docs/en/permissions
- https://code.claude.com/docs/en/headless
- https://code.claude.com/docs/en/sandboxing
