# ADR 0008: usage-hint でセッション開始直後から値を表示する

- Status: Accepted
- Date: 2026-10-07

## Context

usage-hint は最初の API 応答が来るまで、`5h` / `7d` / `ctx` がすべて `--` になる。
エンジンがレートリミット窓とコンテキストの使用量を、応答のたびにしか報告しないため。

- レートリミット窓はアカウント単位で、前のセッションの値もそのまま意味を持つ。
  ただし `resetsAt` を過ぎた窓はリセット済みで、使用量は 0 になっている。
- `$.store` はセッションをまたいで値を保持できる。
- `$.session.usage({ breakdown: 'summary' })` は API を呼ばず、コンテキストの
  トークン数 (`breakdown.totalTokens`) をローカルで推定できる。

## Decision

- `session.measure` で受け取ったレートリミット窓を `$.store` (`rateLimits`) に保存する。
- `session.start` でエンジンがまだ窓を報告していなければ、保存済みの窓を使う。
  `resetsAt` を過ぎた窓は使用量 0、リセット時刻不明として扱う。
- `session.start` でコンテキストの使用率がまだ無ければ、`breakdown: 'summary'` の
  `totalTokens` をモデルのコンテキスト窓 (`context.window`) で割った推定値を使う。
- `session.measure` が窓を空で報告した場合は、直前の窓を残す。
- 最初の応答が来たら、従来どおりエンジンの値で上書きする。

## Consequences

- セッション開始直後から 4 項目のうち Fable 以外が表示される。
- 開始直後の 5h / 7d は前回保存した値なので、別の場所 (Chat タブ等) で使った分は
  最初の応答まで反映されない。
- 開始直後の ctx はローカルの推定値で、最初の応答の値とずれることがある。
