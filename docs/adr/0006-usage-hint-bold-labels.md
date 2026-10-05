# ADR 0006: usage-hint の項目ラベルを太字にする

- Status: Accepted
- Date: 2026-10-05

## Context

usage-hint の表示 (`5h 23% · 7d 41% · Fable -- · ctx 37%`) は全体が dim で、
どこからどこまでが 1 項目なのか読み取りにくい。

## Decision

- 各項目を `<Text>` で包み、その中のラベル (`5h`, `7d`, `Fable`, `ctx`) だけを
  入れ子の `<Text bold>` にする。色 (dim / 75% 超の黄色, ADR 0005) は外側の
  `<Text>` に付け、ラベルにも同じ色が掛かる。
- そのために `Segment` を `{ label, value, isWarning }` に分ける。
  `formatUsage` の文字列表現は変えない。

## Consequences

- CLI / デスクトップの両方でラベルが太字になり、項目の区切りが分かりやすくなる。
- 表示文字列 (`/usage-hint` やテストで使う連結表現) は従来どおり。
