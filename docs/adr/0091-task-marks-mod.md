# ADR 0091: 完了したタスクを [完了] と表示する Claude Code mod (task-marks)

ステータス: 採択

## 文脈

Claude Code のタスクリスト (TaskCreate・TaskUpdate・TodoWrite で作る一覧) では、完了した項目が目立たない。
完了した項目に `[完了]` と付けて、目立たせたい。

Claude Code 2.1.317 の mod の API (型定義) を調べた結果は次のとおり。

- `ui.render` で描き換えられる部品 (`RenderComponent`) は `ToolUse`・`ToolResult`・`Spinner`・`AbovePrompt`・`Pane` などで、
  標準のタスクリストは含まれない。標準のタスクリストの表示は変えられない。
- `tool.call` の hook では、タスクの呼び出しの入力と結果を読める。
  - TaskCreate の結果: `task.id`・`task.subject`
  - TaskUpdate の入力: `taskId`・`status` (`pending`・`in_progress`・`completed`・`deleted`)・`subject`
  - TaskList の結果: `tasks` (各項目の `id`・`subject`・`status`)
  - TodoWrite の結果: `newTodos` (各項目の `content`・`status`)
- そのため、タスクの一覧を mod が自分で持ち、別の場所に描き直すことはできる。
- `$.session.surfaces()` で、セッションがどの面 (`terminal`・`desktop` など) に描いているかを知れる。
- CLI はほとんど使わないので、デスクトップアプリ (Code タブ) だけを対象にする。
- デスクトップの `AbovePrompt` (入力欄のすぐ上の帯) は usage-hint が使っている ([ADR 0004](0004-usage-hint-mod.md))。
  一覧は何行にもなるので、帯ではなく `Pane` (横のペイン) に出す。

## 実装すること

- mod `task-marks` を `.claude/mods/task-marks/` に置く。
  `.claude/settings.json` の `env.CLAUDE_CODE_PLUGIN_DIRS` に、usage-hint と並べて足す (区切りは `:`)。
- `tool.call` の hook で、エラーでない結果だけを読み、セッションの `$.state` に一覧を持つ。
  - TaskCreate: 項目を `pending` で末尾に足す。
  - TaskUpdate: `status` と `subject` を反映する。`deleted` なら項目を消す。
  - TaskList: 結果の `tasks` で一覧を置き換える (取りこぼしをここで直す)。
  - TodoWrite: `newTodos` で、TodoWrite の分の一覧を置き換える。TaskCreate の分とは別に持つ。
- ペイン (タイトル「タスク」) に、作られた順に 1 行ずつ出す。
  - 完了: `[完了] 件名` を緑の太字で出す。
  - 作業中: `[作業中] 件名` を通常の色で出す。
  - 未着手: `[未着手] 件名` を dim で出す。
  - 項目が無いときは「タスクはありません」と dim で出す。
  - 行が入りきらないときは、未完了の項目を優先して残し、古い完了の項目から省く。省いた数を末尾に dim で出す。
- ペインは、セッションで最初のタスクが作られたときに開く。`$.session.surfaces()` に `desktop` が無いとき (CLI) は開かない。
- `/task-marks` コマンドで、いつでもペインを開ける。CLI で打ったときは、デスクトップアプリ専用である旨を返して開かない。
- `ui.render` の hook は `e.surface` が `desktop` のときだけ木を返す。
- 一覧の純粋な処理 (呼び出しの反映、行の組み立て、省略) は `hooks/tasks.ts` に分け、`hooks/register.tsx` は hook だけにする。
- 型は usage-hint と同じく `types/index.d.ts` に置き、`tsconfig.json` は `.claude-plugin/types/tsconfig.json` を extends する
  ([ADR 0061](0061-usage-hint-type-check.md))。
- 仕様書の Claude Code の節に追記する。

## 実装しないこと

- 標準のタスクリストの表示を変えること (API に描き換える部品が無い)。
- セッションを再開したときに、前の一覧を復元すること。再開後の最初の TaskList で一覧が戻る。
- 一覧を `$.store` (セッションをまたぐ保存) に置くこと。
- ペインからタスクの状態を変える操作。表示だけにする。
- CLI (terminal の面) での表示。
- CI での mod のテスト (usage-hint と同じく行わない。[ADR 0046](0046-fix-audit-non-breaking.md))。

## テスト設計

`claude plugin test .claude/mods/task-marks` で動かす。実装の前に書いて、失敗するのを確かめる。

`tests/tasks.test.ts` (純粋な処理):

1. TaskCreate の結果を反映すると、`pending` の項目が末尾に足される。
2. TaskUpdate で `completed` にすると、その項目だけが完了になる。`subject` を渡すと件名が変わる。
3. TaskUpdate で `deleted` にすると、その項目が消える。
4. 知らない `taskId` の TaskUpdate は、一覧を変えない。
5. TaskList の結果で、一覧が置き換わる。
6. TodoWrite の `newTodos` は、TodoWrite の分だけを置き換え、TaskCreate の分を残す。
7. 行の組み立て: 完了は `[完了] `、作業中は `[作業中] `、未着手は `[未着手] ` で始まる。
8. 省略: 入りきらないとき、未完了の項目をすべて残し、古い完了の項目から省き、省いた数を返す。

`tests/register.test.tsx` (hook):

9. TaskCreate と、それを `completed` にする TaskUpdate を流すと、ペインの木に緑の太字の `[完了] 件名` が出る。
10. エラーの結果 (`isError`) は反映しない。
11. desktop の面では、最初の TaskCreate でペインが開く。terminal の面だけなら開かない。
12. desktop の面では `/task-marks` でペインが開く。terminal の面だけなら開かず、その旨を返す。

型検査: `tsc -p .claude/mods/task-marks` が通る。

実機の確かめ: デスクトップアプリで、Claude にタスクを作らせて完了にさせ、ペインに `[完了]` が緑の太字で出ることを見る。

## トレードオフ

- 標準のタスクリストは残るので、同じ一覧が 2 か所に出る。
- 一覧は mod が呼び出しから組み立てた写しで、Claude Code が持つ本物ではない。
  サブエージェントのタスクの呼び出しが `tool.call` に来ない場合や、セッションを再開した場合は、次の TaskList まで食い違う。
- mod の API (`tool.call` の結果の形、`Pane`) に依存するので、Claude Code の更新で壊れることがある。

## 参考文献

- Claude Code 2.1.317 の mod の型定義 (`plugin-authoring` スキルの `types/claude-code.d.ts`): `RenderComponent`、`$.session.surfaces()`、`ToolResultOf` の TaskCreate・TaskUpdate・TaskList・TodoWrite、`ToolCallResult`
- 同スキルの `reference.md` (`Pane`、`CLAUDE_CODE_PLUGIN_DIRS` の区切り) と `examples/pane.tsx`
