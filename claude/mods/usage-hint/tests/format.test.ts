import { describe, expect, test } from 'claude-code/testing'

import { fableLimit, formatUsage } from '../hooks/format'

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
