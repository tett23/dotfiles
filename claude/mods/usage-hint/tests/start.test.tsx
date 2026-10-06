import { expect, mock, test } from 'claude-code/testing'
import type { On, SessionUsage } from 'claude-code'
import type { Engine } from 'claude-code/testing'

const NOW = Date.parse('2026-10-07T12:00:00.000Z')

const BAND_PROPS = {
  hasSurvey: false,
  isWorking: false,
  maxRows: 10,
  bodyColumns: 80,
} as const

// エンジン側: 最初の API 応答前の session.usage と、描画の土台
const engine = (on: On, usage: SessionUsage) => {
  mock.clock(on, { now: NOW })
  on('command.register', ($, e) => ({ value: { command: e.name } }))
  on('session.start', ($, e) => ({ cwd: e.cwd }))
  on('session.usage', () => ({ value: usage }))
  on('session.measure', ($, e) => ({ changed: e.changed }))
  on('ui.render', { component: 'AbovePrompt' }, ($, e) => {
    const { Box } = $.ui.resolve(e)

    return <Box />
  })
}

const BEFORE_FIRST_RESPONSE: SessionUsage = {
  startedAt: NOW,
  context: {
    window: 200_000,
    breakdown: {
      totalTokens: 30_000,
    } as SessionUsage['context']['breakdown'] & object,
  },
  rateLimits: [],
}

const start = ($: Engine) =>
  $.session.start({ cwd: '/tmp', surface: 'desktop', isInteractive: true })

const band = async ($: Engine) =>
  (
    await (
      await $.ui.mount({
        plugin: 'usage-hint',
        surface: 'desktop',
        component: 'AbovePrompt',
        props: BAND_PROPS,
      })
    ).find({ type: 'Box' })
  )?.text

test('開始直後: 前回保存した窓と、推定したコンテキストを出す', async ($, on) => {
  engine(on, BEFORE_FIRST_RESPONSE)
  mock.store(on, {
    rateLimits: [
      { kind: 'five_hour', percentUsed: 80, resetsAt: '2026-10-07T11:00:00.000Z' },
      { kind: 'seven_day', percentUsed: 40, resetsAt: '2026-10-10T00:00:00.000Z' },
    ],
  })
  await start($)

  expect(await band($)).toBe('5h 0% · 7d 40% · Fable -- · ctx 15%')
})

test('保存値が無ければ窓は -- のまま', async ($, on) => {
  engine(on, BEFORE_FIRST_RESPONSE)
  mock.store(on)
  await start($)

  expect(await band($)).toBe('5h -- · 7d -- · Fable -- · ctx 15%')
})

test('measure で受け取った窓を保存し、空の報告では直前の値を残す', async ($, on) => {
  engine(on, BEFORE_FIRST_RESPONSE)
  mock.store(on)
  await start($)
  await $.session.measure({
    context: { window: 200_000, tokens: 20_000, percent: 10 },
    rateLimits: [{ kind: 'five_hour', percentUsed: 12 }],
    changed: ['context', 'rateLimits'],
  })
  await $.session.measure({
    context: { window: 200_000, tokens: 22_000, percent: 11 },
    rateLimits: [],
    changed: ['context'],
  })

  expect(await band($)).toBe('5h 12% · 7d -- · Fable -- · ctx 11%')

  // 次のセッション開始時に、保存した窓が復元される
  await start($)
  expect(await band($)).toBe('5h 12% · 7d -- · Fable -- · ctx 15%')
})
