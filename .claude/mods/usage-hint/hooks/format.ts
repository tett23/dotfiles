import type { Limit, Snapshot } from '../types'

export const SEPARATOR = ' · '

// 75% を超えると warning、90% を超えると danger (docs/adr/0005, 0060)
const WARNING_PERCENT = 75
const DANGER_PERCENT = 90

export type Level = 'normal' | 'warning' | 'danger'

export type Segment = { label: string; value: string; level: Level }

const levelOf = (value: number): Level =>
  value > DANGER_PERCENT ? 'danger' : value > WARNING_PERCENT ? 'warning' : 'normal'

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
    ? { label, value: '--', level: 'normal' }
    : { label, value: `${Math.round(value)}%`, level: levelOf(value) }

// Fable の週のウィンドウの kind。Claude Code 本体もこの kind を「Fable limit」と表示する (docs/adr/0074)
export const FABLE_KIND = 'seven_day_overage_included'

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null

const toFable = (percent: unknown, resetsAt: unknown): Limit | undefined =>
  typeof percent !== 'number'
    ? undefined
    : {
        kind: FABLE_KIND,
        percentUsed: percent,
        ...(typeof resetsAt === 'string' ? { resetsAt } : {}),
      }

const isFableScope = (entry: Record<string, unknown>): boolean => {
  const scope = isRecord(entry.scope) ? entry.scope : {}
  const model = isRecord(scope.model) ? scope.model : {}

  return typeof model.display_name === 'string' && model.display_name.toLowerCase() === 'fable'
}

// 使用量の API (/api/oauth/usage) の応答から Fable の週のウィンドウを取り出す。limits[] のモデル名が Fable のものを優先し、
// 無ければ seven_day_overage_included を使う。応答の形は公開されていないので、形が違えば無しにする (docs/adr/0074)
export const fableFromUsage = (body: unknown): Limit | undefined => {
  if (!isRecord(body)) {
    return undefined
  }
  const entry = (Array.isArray(body.limits) ? body.limits : [])
    .filter(isRecord)
    .find(isFableScope)
  const overage = isRecord(body[FABLE_KIND]) ? body[FABLE_KIND] : undefined

  return (
    (entry && toFable(entry.percent, entry.resets_at)) ??
    (overage && toFable(overage.utilization, overage.resets_at))
  )
}

// 新しいウィンドウに Fable が無ければ、直前の Fable を残す。Fable は API の応答に入らないことが多い (docs/adr/0074)
export const keepFable = (next: readonly Limit[], previous: readonly Limit[]): Limit[] => {
  const kept = byKind(FABLE_KIND)(previous)

  return kept && !byKind(FABLE_KIND)(next) ? [...next, kept] : [...next]
}

// limits の同じ kind のウィンドウを limit で置き換える (無ければ足す)
export const withLimit = (limits: readonly Limit[], limit: Limit): Limit[] => [
  ...limits.filter(({ kind }) => kind !== limit.kind),
  limit,
]

export const usageSegments =({ contextPercent, rateLimits }: Snapshot): Segment[] => [
  segment('5h', byKind('five_hour')(rateLimits)?.percentUsed),
  segment('7d', byKind('seven_day')(rateLimits)?.percentUsed),
  segment('Fable', fableLimit(rateLimits)?.percentUsed),
  segment('ctx', contextPercent),
]

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
