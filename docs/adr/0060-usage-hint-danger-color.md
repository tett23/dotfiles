# ADR 0060: usage-hint で 90% を超えた項目を赤にし、警告の色を暗めにする

ステータス: 採択

## 文脈

usage-hint は、75% を超えた項目を黄色 (`color: 'yellow'`) で、それ以外を `dimColor` で描いている
([ADR 0005](0005-usage-hint-warning-color.md))。本人から次の要望があった。

- 90% を超えた項目は赤で出したい (上限が目前であることに気づけるように)。
- 色が見づらいので、暗めの色にしたい。

調べた結果は次のとおり。

- Claude Code の mod の `Text` の `color` は、テーマの色の名前 (`warning`・`error` など) か、色の名前 (`yellow` など)・16 進の色を受け付ける
  (`.claude-plugin/types/claude-code/index.d.ts` の `Color`)。
- 端末 (Ghostty) の背景は Monokai Classic の `#272822`。`yellow`・`red` は端末の明るい原色で描かれ、まわりの dim の文字より強く目立つ。
- 項目の警告は `usageSegments` (`hooks/format.ts`) が `isWarning` (真偽値) で返し、`hooks/register.tsx` の `toText` が色を決めている。

## 実装すること

- 項目の段階を 3 つにする。値が無い (`--`) 項目は `normal`。

  | 段階 | 条件 | 描き方 |
  |---|---|---|
  | `normal` | 75% 以下 | `dimColor` (今と同じ) |
  | `warning` | 75% を超え 90% 以下 | 暗めの黄色 `#b39020` |
  | `danger` | 90% を超える | 暗めの赤 `#b5403a` |

  - 色の値は試用のうえで本人が変えることがある。値を変えるだけなら新しい ADR は作らない。
- terminal (`PromptHint`) と desktop (`AbovePrompt`) の両方に同じ描き方を使う (今と同じ)。
- `docs/specifications.md` の usage-hint の記述を直す。

## データ構造の変更

- `Segment` の `isWarning: boolean` を `level: 'normal' | 'warning' | 'danger'` に置き換える。
  段階の判定 (しきい値) は `hooks/format.ts`、段階から色への対応は `hooks/register.tsx` に置く。

## 実装しないこと

- しきい値・色を設定で変えられるようにすること。
- 項目ごとに違うしきい値を使うこと (5h・7d・Fable・ctx は同じしきい値)。
- 値が無い項目 (`--`) やラベルの描き方の変更。

## テスト設計

- `tests/format.test.ts`: `usageSegments` が、75% ちょうど (四捨五入の前の値で判定) は `normal`、75% を超えると `warning`、
  90% ちょうどは `warning`、90% を超えると `danger`、値が無いと `normal` を返すこと。
- `tests/register.test.tsx`: terminal と desktop の両方で、`warning` の項目が `#b39020`、`danger` の項目が `#b5403a`、
  `normal` の項目が色無し (`dimColor`) で描かれること。
- 先にテストを直して失敗させてから実装する。`claude plugin test .claude/mods/usage-hint` がすべて通ること。
- 実際の見え方は本人が確かめる。

## トレードオフ

- 色を暗くしたので、黄色・赤が今より目立たなくなる (dim の文字との差が小さくなる)。
- 16 進の色を直接書くので、Claude Code のテーマ (明るい背景など) を変えても色は変わらない。
