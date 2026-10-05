# ADR 0005: usage-hint で 75% を超えた項目を黄色で表示する

- Status: Accepted
- Date: 2026-10-05
- Supersedes: ADR 0004 の「terminal は `PromptHint` の `tail` で追記する」部分

## Context

上限に近づいたことに気づけるよう、75% を超えた項目を黄色で表示したい。

- terminal の `PromptHint` の `tail` は文字列 1 本で、エンジンが dim で描く。
  項目ごとに色を変えることはできない。
- `PromptHint` は hook が自前のツリーを返して行ごと描くこともできる。その場合、
  エンジンのヒント行 (ピル) は `props.hint` の文字列として描き直すことになり、
  ピルの見た目やクリック等の挙動は失われる。
- desktop の `AbovePrompt` は元から自前のツリーなので色を付けられる。
- デスクトップの Chat タブ (claude.ai の通常チャット) は Claude Code ではなく、
  mod の仕組みが届かない。表示は対象外とする。

## Decision

- 各項目は `percent > 75` のとき `color="yellow"`、それ以外は `dimColor` で描く。
  値が無い (`--`) 項目は警告にしない。
- terminal は `PromptHint` を自前のツリーで描く: `props.hint` を dim で描き、
  続けて区切り ` · ` と 4 項目を並べる。`tail` は使わない。
- desktop は `AbovePrompt` の帯をそのまま使い、同じ項目ツリーを描く。
- 表示文字列の組み立ては `usageSegments` (項目ごとの `{ text, isWarning }`) に
  まとめ、`formatUsage` はその連結にする。

## Consequences

- 75% を超えた項目が CLI / デスクトップの両方で黄色になる。
- CLI のヒント行は mod が描き直すため、エンジンのピルが文字列表示になる。
  不都合があれば新しい ADR で `tail` 方式 (色なし) に戻すか決める。
- Chat タブには引き続き表示されない。
