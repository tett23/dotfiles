# ADR 0065: usage-hint の 1 分ごとの更新を、/clear の後も続ける

ステータス: 採択

## 文脈

[ADR 0063](0063-usage-hint-periodic-refresh.md) で、usage-hint は `session.start` で 1 分ごとの更新 (`$.clock.every`) を始め、
`session.end` で止めるようにした。

Claude Code の mod の型定義 (`SessionEndInput` の `reason`) によると、`/clear` では `session.end` が `reason: 'clear'` で来るが、
会話が終わるだけでプロセスは新しいセッション ID で続き、新しい会話の `session.start` は来ない。そのため今の実装では、
`/clear` の後は 1 分ごとの更新が止まったままになり、[ADR 0063](0063-usage-hint-periodic-refresh.md) で直したかった「古い使用率が出たままになる」ことが再び起きる。

テストで確かめた (`/clear` の理由で `session.end` を送った後に時計を 1 分進めると、`session.usage` の新しい値が表示に出ない)。

## 実装すること

- `session.end` の `reason` が `clear` のときは、1 分ごとの更新を止めない。それ以外の理由 (`prompt_input_exit`・`resume`・`logout`・`other` など) では、今どおり止める。
- `docs/specifications.md` の usage-hint の 1 分ごとの更新の記述に、`/clear` の後も続けることを書く。

## 実装しないこと

- `/clear` のときに表示の値を消すこと (レートリミットの窓はアカウントのもので、会話が変わっても変わらない。
  コンテキストの使用率は、次の `session.measure` か 1 分ごとの更新で新しい会話の値になる)。
- `resume` で別のセッションに替わったときの扱いの変更 (新しいセッションの `session.start` が来るので、そこで始め直す)。

## テスト設計

`tests/refresh.test.tsx` に次のテストを足す。先に書いて失敗させてから実装する。

- `session.end` を `reason: 'clear'` で送った後に時計を 1 分進めると、`session.usage` の新しい窓が表示に出ること。
- 既存の「セッションが終わった後は読まない」テスト (`clear` 以外の理由) が引き続き通ること。
- `claude plugin test .claude/mods/usage-hint` がすべて通り、`tsc --noEmit -p .` がエラー 0 で終わること。

## トレードオフ

- `clear` 以外の理由で終わったのに、プロセスが続く場合があれば、そのときは更新が止まる (型定義の説明では、プロセスが続くのは `clear` だけ)。
