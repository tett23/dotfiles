import { describe, expect, test } from 'claude-code/testing'

import {
  estimatePercent,
  fableLimit,
  formatUsage,
  parseLimits,
  restoreLimits,
  usageSegments,
} from '../hooks/format'

describe('formatUsage', () => {
  test('4 項目を % で並べる', () => {
    const text = formatUsage({
      contextPercent: 37,
      rateLimits: [
        { kind: 'five_hour', percentUsed: 23 },
        { kind: 'seven_day', percentUsed: 41.5 },
        { kind: 'seven_day_overage_included', percentUsed: 12 },
      ],
    })

    expect(text).toBe('5h 23% · 7d 42% · Fable 12% · ctx 37%')
  })

  test('値が無い項目は -- にする', () => {
    expect(formatUsage({ contextPercent: null, rateLimits: [] })).toBe(
      '5h -- · 7d -- · Fable -- · ctx --',
    )
  })
})

describe('fableLimit', () => {
  test('fable を含む kind を overage_included より優先する', () => {
    const limit = fableLimit([
      { kind: 'seven_day_overage_included', percentUsed: 1 },
      { kind: 'seven_day_fable', percentUsed: 2 },
    ])

    expect(limit?.percentUsed).toBe(2)
  })

  test('コードネームの seven_day_omelette は Fable と見なさない', () => {
    expect(fableLimit([{ kind: 'seven_day_omelette', percentUsed: 5 }])).toBeUndefined()
  })
})

describe('usageSegments', () => {
  test('75% を超えた項目だけ警告にする', () => {
    const segments = usageSegments({
      contextPercent: 75,
      rateLimits: [
        { kind: 'five_hour', percentUsed: 75.4 },
        { kind: 'seven_day', percentUsed: 75.6 },
      ],
    })

    expect(segments).toEqual([
      { label: '5h', value: '75%', isWarning: true },
      { label: '7d', value: '76%', isWarning: true },
      { label: 'Fable', value: '--', isWarning: false },
      { label: 'ctx', value: '75%', isWarning: false },
    ])
  })
})

describe('parseLimits', () => {
  test('保存値のうち形の正しい窓だけを取り出す', () => {
    const stored = [
      { kind: 'five_hour', percentUsed: 10, resetsAt: '2026-10-07T10:00:00.000Z' },
      { kind: 'seven_day', percentUsed: 'x' },
      'garbage',
    ]

    expect(parseLimits(stored)).toEqual([
      { kind: 'five_hour', percentUsed: 10, resetsAt: '2026-10-07T10:00:00.000Z' },
    ])
  })

  test('配列でなければ空', () => {
    expect(parseLimits(undefined)).toEqual([])
  })
})

describe('restoreLimits', () => {
  const NOW = Date.parse('2026-10-07T12:00:00.000Z')

  test('リセット時刻を過ぎた窓は 0% でリセット時刻不明にする', () => {
    const limits = restoreLimits(
      [
        { kind: 'five_hour', percentUsed: 80, resetsAt: '2026-10-07T11:00:00.000Z' },
        { kind: 'seven_day', percentUsed: 40, resetsAt: '2026-10-10T00:00:00.000Z' },
        { kind: 'seven_day_sonnet', percentUsed: 5 },
      ],
      NOW,
    )

    expect(limits).toEqual([
      { kind: 'five_hour', percentUsed: 0 },
      { kind: 'seven_day', percentUsed: 40, resetsAt: '2026-10-10T00:00:00.000Z' },
      { kind: 'seven_day_sonnet', percentUsed: 5 },
    ])
  })
})

describe('estimatePercent', () => {
  test('トークン数をコンテキスト窓に対する整数 % にする', () => {
    expect(estimatePercent(25_000, 200_000)).toBe(13)
  })

  test('窓が 0 なら null', () => {
    expect(estimatePercent(100, 0)).toBeNull()
  })
})
