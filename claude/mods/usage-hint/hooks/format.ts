import type { Limit, Snapshot } from '../types'

export const SEPARATOR = ' · '

const WARNING_PERCENT = 75

export type Segment = { text: string; isWarning: boolean }

const byKind =
  (kind: string) =>
  (limits: readonly Limit[]): Limit | undefined =>
    limits.find(limit => limit.kind === kind)

// Fable の込み使用量は Fable へのリクエスト時だけ API が返す
// seven_day_overage_included 窓と推定する。fable を含む kind があればそちらを優先する
// (docs/adr/0004)
export const fableLimit = (limits: readonly Limit[]): Limit | undefined =>
  limits.find(limit => limit.kind.includes('fable')) ??
  byKind('seven_day_overage_included')(limits)

const segment = (label: string, value: number | null | undefined): Segment =>
  value === null || value === undefined
    ? { text: `${label} --`, isWarning: false }
    : { text: `${label} ${Math.round(value)}%`, isWarning: value > WARNING_PERCENT }

export const usageSegments = ({ contextPercent, rateLimits }: Snapshot): Segment[] => [
  segment('5h', byKind('five_hour')(rateLimits)?.percentUsed),
  segment('7d', byKind('seven_day')(rateLimits)?.percentUsed),
  segment('Fable', fableLimit(rateLimits)?.percentUsed),
  segment('ctx', contextPercent),
]

export const formatUsage = (snapshot: Snapshot): string =>
  usageSegments(snapshot)
    .map(({ text }) => text)
    .join(SEPARATOR)
