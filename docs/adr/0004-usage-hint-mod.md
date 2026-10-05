# ADR 0004: 入力欄の下に使用量を表示する Claude Code mod (usage-hint)

- Status: Accepted
- Date: 2026-10-05

## Context

CLI とデスクトップアプリ (Code タブ) の両方で、チャット入力欄の下に次の 4 つを
% で常時表示したい。

1. 5 時間上限
2. 今週の上限
3. Fable 使用量の上限
4. 現在のセッションのコンテキスト使用率

既存の `statusLine` (settings.json) は CLI 専用で、デスクトップには出ない。

Claude Code の mod (function hooks のプラグイン) では次が使える。

- `ui.render` の `PromptHint` コンポーネント: 入力欄の下の dim なヒント行。
  型定義上は terminal と desktop で発火し、terminal では `props.tail` で既存行の
  末尾に追記できる (ピル等は残る)。
- ただしデスクトップアプリ (2.19675.0) が mod の描画先として扱うのは `Pane` と
  `AbovePrompt` (入力欄のすぐ上の帯) だけで、`PromptHint` は描かれないことを
  実機で確認した。デスクトップで入力欄の下に出す手段は無い。
- `session.measure` イベント / `$.session.usage()`: コンテキストの `percent` と、
  レートリミット窓 (`rateLimits`: `kind`, `percentUsed`, `resetsAt`)。

Fable の上限は週ごとの「included Fable usage」。実測 (2026-10-05) では次のとおり。

- haiku へのリクエストで API が返す窓は `five_hour` と `seven_day` のみ。
- Fable へのリクエストではこれに `seven_day_overage_included` が加わる。
  エンジン内に `usage: overage-included models allowlist` という設定があり、
  プラン込み枠を持つモデル (Fable) の週枠と推定できる。
- ただし mod が受け取る `rateLimits` には、Fable 時でも `five_hour` と
  `seven_day` しか入らない。エンジンが残りを渡していない。
- `/api/oauth/usage` を `$.session.authorize()` 経由で直接問い合わせる方法は、
  認証情報の扱いになるため採用しない。

## Decision

- mod `usage-hint` を `claude/mods/usage-hint/` に置き、dotfiles で管理する。
- 表示は `5h 23% · 7d 41% · Fable 12% · ctx 37%`。値が無い項目は `--`。
- 表示位置は surface ごとに分ける。terminal は `PromptHint` の `tail` で入力欄の下に、
  desktop は `AbovePrompt` で入力欄のすぐ上に出す。アンケート表示中 (`hasSurvey`)
  は帯を譲る。
- データは `session.start` で `$.session.usage()`、以降は `session.measure` で
  受け取り、`$.state` (atom) に保持する。描画時はそれを読むだけにする。
- Fable 枠は `kind` が `fable` を含むもの、無ければ `seven_day_overage_included`
  を採用する。現状のエンジンはどちらも渡さないため `--` になるが、渡され始めれば
  そのまま表示される。受信した `rateLimits` をそのまま表示する `/usage-hint`
  コマンドを付け、届いている窓を確認できるようにする。
- 読み込みは `claude/settings.json` の `env.CLAUDE_CODE_PLUGIN_DIRS` で行う。
  `~/.claude/settings.json` の `env` は CLI とデスクトップの両方に効く。
- テストは `claude plugin test` で、terminal / desktop の両 surface に対して書く。

## Consequences

- CLI では入力欄の下、デスクトップでは入力欄のすぐ上に 4 項目が出る。
  デスクトップが `PromptHint` に対応したら、新しい ADR で下に移すか決める。
- `rateLimits` はサブスクリプション利用時のみ、かつ最初の API 応答後に届くため、
  セッション開始直後は `--` になる。
- 現状の Claude Code (2.1.289) では Fable 列は常に `--` になる。エンジンが
  窓を渡すようになったら自動で表示される。別の手段を取る場合は新しい ADR で決める。
- `PromptHint` / `session.measure` は mod API の仕様に依存するため、
  Claude Code の更新で壊れる可能性がある。
