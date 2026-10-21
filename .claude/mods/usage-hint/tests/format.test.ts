import { describe, expect, test } from 'claude-code/testing'

import {
  estimatePercent,
  fableFromUsage,
  fableLimit,
  keepFable,
  parseLimits,
  restoreLimits,
  usageSegments,
} from '../hooks/format'

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
  test('75% を超えた項目を warning にする (判定は四捨五入の前の値)', () => {
    const segments = usageSegments({
      contextPercent: 75,
      rateLimits: [
        { kind: 'five_hour', percentUsed: 75.4 },
        { kind: 'seven_day', percentUsed: 75.6 },
      ],
    })

    expect(segments).toEqual([
      { label: '5h', value: '75%', level: 'warning' },
      { label: '7d', value: '76%', level: 'warning' },
      { label: 'Fable', value: '--', level: 'normal' },
      { label: 'ctx', value: '75%', level: 'normal' },
    ])
  })

  test('90% を超えた項目を danger にする。90% ちょうどは warning (docs/adr/0060)', () => {
    const segments = usageSegments({
      contextPercent: 90,
      rateLimits: [
        { kind: 'five_hour', percentUsed: 90.2 },
        { kind: 'seven_day', percentUsed: 100 },
        { kind: 'seven_day_overage_included', percentUsed: 89.9 },
      ],
    })

    expect(segments).toEqual([
      { label: '5h', value: '90%', level: 'danger' },
      { label: '7d', value: '100%', level: 'danger' },
      { label: 'Fable', value: '90%', level: 'warning' },
      { label: 'ctx', value: '90%', level: 'warning' },
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

// 使用量の API (/api/oauth/usage) の応答から Fable の週のウィンドウを取り出す (docs/adr/0074)
describe('fableFromUsage', () => {
  const fable = (displayName: string, percent: unknown, resetsAt?: unknown) => ({
    scope: { model: { display_name: displayName } },
    percent,
    ...(resetsAt === undefined ? {} : { resets_at: resetsAt }),
  })

  test('limits[] のモデル名が Fable のものを、seven_day_overage_included として返す', () => {
    expect(
      fableFromUsage({
        limits: [fable('Opus', 10), fable('Fable', 42.5, '2026-10-25T00:00:00Z')],
        seven_day_overage_included: { utilization: 1, resets_at: null },
      }),
    ).toEqual({
      kind: 'seven_day_overage_included',
      percentUsed: 42.5,
      resetsAt: '2026-10-25T00:00:00Z',
    })
  })

  test('モデル名の大文字・小文字は区別しない', () => {
    expect(fableFromUsage({ limits: [fable('fable', 7)] })?.percentUsed).toBe(7)
  })

  test('limits[] に無ければ seven_day_overage_included を使う', () => {
    expect(
      fableFromUsage({
        seven_day_overage_included: { utilization: 30, resets_at: '2026-10-25T00:00:00Z' },
      }),
    ).toEqual({
      kind: 'seven_day_overage_included',
      percentUsed: 30,
      resetsAt: '2026-10-25T00:00:00Z',
    })
  })

  test('リセット時刻が無い・null なら resetsAt を付けない', () => {
    expect(
      fableFromUsage({ seven_day_overage_included: { utilization: 30, resets_at: null } }),
    ).toEqual({ kind: 'seven_day_overage_included', percentUsed: 30 })
  })

  test('どちらも無い・形が違うときは無し', () => {
    expect(fableFromUsage({})).toBeUndefined()
    expect(fableFromUsage(null)).toBeUndefined()
    expect(fableFromUsage('text')).toBeUndefined()
    expect(fableFromUsage({ limits: 'x', seven_day_overage_included: null })).toBeUndefined()
    expect(fableFromUsage({ limits: [fable('Fable', '42')] })).toBeUndefined()
    expect(
      fableFromUsage({ seven_day_overage_included: { utilization: null, resets_at: null } }),
    ).toBeUndefined()
  })
})

// 新しいウィンドウに Fable が無ければ、直前の Fable を残す (docs/adr/0074)
describe('keepFable', () => {
  const FABLE = { kind: 'seven_day_overage_included', percentUsed: 42 }

  test('新しいウィンドウに Fable が無ければ、直前の Fable を足す', () => {
    expect(keepFable([{ kind: 'five_hour', percentUsed: 10 }], [FABLE])).toEqual([
      { kind: 'five_hour', percentUsed: 10 },
      FABLE,
    ])
  })

  test('新しいウィンドウに Fable があれば、それを使う', () => {
    const next = { kind: 'seven_day_overage_included', percentUsed: 50 }
    expect(keepFable([next], [FABLE])).toEqual([next])
  })

  test('直前に Fable が無ければ、新しいウィンドウのまま', () => {
    expect(keepFable([{ kind: 'five_hour', percentUsed: 10 }], [])).toEqual([
      { kind: 'five_hour', percentUsed: 10 },
    ])
  })
})
