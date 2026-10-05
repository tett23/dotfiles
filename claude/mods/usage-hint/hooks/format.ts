import type { Limit, Snapshot } from '../types'

const SEPARATOR = ' · '

const percent = (value: number | null | undefined): string =>
  value === null || value === undefined ? '--' : `${Math.round(value)}%`

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

export const formatUsage = ({ contextPercent, rateLimits }: Snapshot): string =>
  [
    `5h ${percent(byKind('five_hour')(rateLimits)?.percentUsed)}`,
    `7d ${percent(byKind('seven_day')(rateLimits)?.percentUsed)}`,
    `Fable ${percent(fableLimit(rateLimits)?.percentUsed)}`,
    `ctx ${percent(contextPercent)}`,
  ].join(SEPARATOR)
