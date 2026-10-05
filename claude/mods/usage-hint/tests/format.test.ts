import { describe, expect, test } from 'claude-code/testing'

import { fableLimit, formatUsage, usageSegments } from '../hooks/format'

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
