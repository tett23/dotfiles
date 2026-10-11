import type { Limit, Snapshot } from '../types'

export const SEPARATOR = ' · '

const WARNING_PERCENT = 75

export type Segment = { label: string; value: string; isWarning: boolean }

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
    ? { label, value: '--', isWarning: false }
    : { label, value: `${Math.round(value)}%`, isWarning: value > WARNING_PERCENT }

export const usageSegments = ({ contextPercent, rateLimits }: Snapshot): Segment[] => [
  segment('5h', byKind('five_hour')(rateLimits)?.percentUsed),
  segment('7d', byKind('seven_day')(rateLimits)?.percentUsed),
  segment('Fable', fableLimit(rateLimits)?.percentUsed),
  segment('ctx', contextPercent),
]

export const formatUsage = (snapshot: Snapshot): string =>
  usageSegments(snapshot)
    .map(({ label, value }) => `${label} ${value}`)
    .join(SEPARATOR)

const isLimit = (value: unknown): value is Limit => {
  if (typeof value !== 'object' || value === null) {
    return false
  }
  const { kind, percentUsed, resetsAt } = value as Record<string, unknown>

  return (
    typeof kind === 'string' &&
    typeof percentUsed === 'number' &&
    (resetsAt === undefined || typeof resetsAt === 'string')
  )
}

// $.store の値は unknown なので、形の正しい窓だけを取り出す
export const parseLimits = (stored: unknown): Limit[] =>
  Array.isArray(stored) ? stored.filter(isLimit) : []

// リセット時刻を過ぎた窓は使用量 0、次のリセット時刻は不明として扱う (docs/adr/0008)
export const restoreLimits = (limits: readonly Limit[], now: number): Limit[] =>
  limits.map(limit =>
    limit.resetsAt !== undefined && Date.parse(limit.resetsAt) <= now
      ? { kind: limit.kind, percentUsed: 0 }
      : limit,
  )

export const estimatePercent = (tokens: number, window: number): number | null =>
  window > 0 ? Math.round((tokens / window) * 100) : null
