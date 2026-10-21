import { expect, mock, test } from 'claude-code/testing'
import type { MockClock } from 'claude-code/testing'
import type { On, RenderSurface, SessionAuthorization, SessionUsage } from 'claude-code'
import type { Engine } from 'claude-code/testing'

// 表示中のセッションで、1 分ごとに表示の値を更新する (docs/adr/0063)

const NOW = Date.parse('2026-10-07T12:00:00.000Z')
const MINUTE = 60_000

const BAND_PROPS = {
  hasSurvey: false,
  isWorking: false,
  maxRows: 10,
  bodyColumns: 80,
  scroll: { offset: 0, bodyRows: 10 },
  view: {},
} as const

type World = {
  clock: MockClock
  usage: SessionUsage
  surfaces: readonly RenderSurface[]
  usageCalls: number
  // 使用量の API (docs/adr/0074): 認証の handle、応答の本文 (undefined なら失敗)、受けたリクエスト
  authorization: SessionAuthorization
  usageBody: unknown
  fetches: { url: string; auth?: string }[]
}

const usageWith = (rateLimits: SessionUsage['rateLimits'], percent?: number): SessionUsage => ({
  startedAt: NOW,
  context: { window: 200_000, ...(percent === undefined ? {} : { percent }) },
  rateLimits,
})

// エンジン側: session.usage と session.surfaces は world の今の値を返す
const engine = (on: On, usage: SessionUsage): World => {
  const world: World = {
    clock: mock.clock(on, { now: NOW }),
    usage,
    surfaces: ['desktop'],
    usageCalls: 0,
    authorization: null,
    usageBody: undefined,
    fetches: [],
  }
  mock.store(on)
  on('command.register', ($, e) => ({ value: { command: e.name } }))
  on('session.start', ($, e) => ({ cwd: e.cwd }))
  on('session.end', ($, e) => ({ sessionId: e.sessionId }))
  on('session.usage', () => {
    world.usageCalls += 1

    return { value: world.usage }
  })
  on('session.surfaces', () => ({ value: world.surfaces }))
  on('session.authorize', () => ({ value: world.authorization }))
  on('http.fetch', ($, e) => {
    world.fetches.push({ url: e.url, auth: e.init?.auth })
    if (world.usageBody === undefined) {
      return { value: { status: 500, ok: false, headers: {}, text: '' } }
    }

    return { value: { status: 200, ok: true, headers: {}, text: JSON.stringify(world.usageBody) } }
  })
  on('session.measure', ($, e) => ({ changed: e.changed }))
  on('ui.render', { component: 'AbovePrompt' }, ($, e) => {
    const { Box } = $.ui.resolve(e)

    return <Box />
  })

  return world
}

const start = ($: Engine) =>
  $.session.start({ cwd: '/tmp', surface: 'desktop', isInteractive: true })

const mount = ($: Engine) =>
  $.ui.mount({
    plugin: 'usage-hint',
    surface: 'desktop',
    component: 'AbovePrompt',
    props: BAND_PROPS,
  })

const band = async ($: Engine) => (await (await mount($)).find({ type: 'Box' }))?.text

const FIVE_HOUR_RESET = '2026-10-07T12:30:00.000Z'

test('開始の 1 分後に、session.usage の新しい窓を出す', async ($, on) => {
  const world = engine(on, usageWith([{ kind: 'five_hour', percentUsed: 10 }], 20))
  await start($)
  expect(await band($)).toBe('5h 10% · 7d -- · Fable -- · ctx 20%')

  world.usage = usageWith(
    [
      { kind: 'five_hour', percentUsed: 30 },
      { kind: 'seven_day', percentUsed: 50 },
    ],
    25,
  )
  await world.clock.advance(MINUTE)

  expect(await band($)).toBe('5h 30% · 7d 50% · Fable -- · ctx 25%')
})

test('リセット時刻を過ぎた窓は、1 分以内の更新で 0% になり、色が dim に戻る', async ($, on) => {
  const world = engine(
    on,
    usageWith([{ kind: 'five_hour', percentUsed: 95, resetsAt: FIVE_HOUR_RESET }], 20),
  )
  await start($)
  const before = await mount($)
  expect((await before.find({ type: 'Text', text: '5h 95%' }))?.props.color).toBe('#b5403a')

  // リセットの 30 分後。窓の値は API の応答が無いので古いまま
  await world.clock.advance(30 * MINUTE)

  expect(await band($)).toBe('5h 0% · 7d -- · Fable -- · ctx 20%')
  const after = await mount($)
  expect((await after.find({ type: 'Text', text: '5h 0%' }))?.props.dimColor).toBe(true)
})

test('session.usage の窓が空なら直前の窓を残し、リセット時刻を過ぎたものだけ 0% にする', async ($, on) => {
  const world = engine(
    on,
    usageWith(
      [
        { kind: 'five_hour', percentUsed: 60, resetsAt: FIVE_HOUR_RESET },
        { kind: 'seven_day', percentUsed: 40, resetsAt: '2026-10-10T00:00:00.000Z' },
      ],
      20,
    ),
  )
  await start($)
  world.usage = usageWith([])

  await world.clock.advance(MINUTE)
  expect(await band($)).toBe('5h 60% · 7d 40% · Fable -- · ctx 20%')

  await world.clock.advance(30 * MINUTE)
  expect(await band($)).toBe('5h 0% · 7d 40% · Fable -- · ctx 20%')
})

test('1 分たたないうちは更新しない', async ($, on) => {
  const world = engine(on, usageWith([{ kind: 'five_hour', percentUsed: 10 }], 20))
  await start($)
  const afterStart = world.usageCalls

  await world.clock.advance(MINUTE - 1)
  expect(world.usageCalls).toBe(afterStart)

  await world.clock.advance(1)
  expect(world.usageCalls).toBe(afterStart + 1)
})

test('どの画面も表示していない間は更新せず、表示に戻ると次の 1 分で更新する', async ($, on) => {
  const world = engine(on, usageWith([{ kind: 'five_hour', percentUsed: 10 }], 20))
  await start($)
  const afterStart = world.usageCalls

  world.surfaces = []
  world.usage = usageWith([{ kind: 'five_hour', percentUsed: 30 }], 20)
  await world.clock.advance(3 * MINUTE)
  expect(world.usageCalls).toBe(afterStart)
  expect(await band($)).toBe('5h 10% · 7d -- · Fable -- · ctx 20%')

  world.surfaces = ['terminal']
  await world.clock.advance(MINUTE)
  expect(world.usageCalls).toBe(afterStart + 1)
  expect(await band($)).toBe('5h 30% · 7d -- · Fable -- · ctx 20%')
})

test('session.end の後は更新しない', async ($, on) => {
  const world = engine(on, usageWith([{ kind: 'five_hour', percentUsed: 10 }], 20))
  await start($)
  await $.session.end({
    reason: 'prompt_input_exit',
    sessionId: 'session',
    resume: { id: 'session' },
  })
  const afterEnd = world.usageCalls

  await world.clock.advance(5 * MINUTE)
  expect(world.usageCalls).toBe(afterEnd)
})

// /clear では session.end が来るが、同じプロセスで次の会話が続き session.start は来ない (docs/adr/0065)
test('/clear の後も 1 分ごとの更新を続ける', async ($, on) => {
  const world = engine(on, usageWith([{ kind: 'five_hour', percentUsed: 10 }], 20))
  await start($)
  await $.session.end({
    reason: 'clear',
    sessionId: 'session',
    resume: { id: 'session' },
  })

  world.usage = usageWith([{ kind: 'five_hour', percentUsed: 30 }], 5)
  await world.clock.advance(MINUTE)
  expect(await band($)).toBe('5h 30% · 7d -- · Fable -- · ctx 5%')
})

// 使用量の API から Fable の週のウィンドウを取る (docs/adr/0074)
const USAGE_URL = 'https://api.anthropic.com/api/oauth/usage'
const fableBody = (percent: number) => ({
  limits: [{ scope: { model: { display_name: 'Fable' } }, percent, resets_at: '2026-10-10T00:00:00.000Z' }],
})

test('開始時に、使用量の API から Fable の値を出す。リクエストには認証の handle を付ける', async ($, on) => {
  const world = engine(on, usageWith([{ kind: 'five_hour', percentUsed: 10 }], 20))
  world.authorization = { handle: 'h1', kind: 'bearer' }
  world.usageBody = fableBody(42)
  await start($)

  expect(await band($)).toBe('5h 10% · 7d -- · Fable 42% · ctx 20%')
  expect(world.fetches).toEqual([{ url: USAGE_URL, auth: 'h1' }])
})

test('Fable の値は 5 分ごとに問い合わせる (1 分ごとの更新では問い合わせない)', async ($, on) => {
  const world = engine(on, usageWith([{ kind: 'five_hour', percentUsed: 10 }], 20))
  world.authorization = { handle: 'h1', kind: 'bearer' }
  world.usageBody = fableBody(42)
  await start($)

  world.usageBody = fableBody(55)
  await world.clock.advance(4 * MINUTE)
  expect(world.fetches.length).toBe(1)
  expect(await band($)).toBe('5h 10% · 7d -- · Fable 42% · ctx 20%')

  await world.clock.advance(MINUTE)
  expect(world.fetches.length).toBe(2)
  expect(await band($)).toBe('5h 10% · 7d -- · Fable 55% · ctx 20%')
})

test('認証の handle が無ければ問い合わせず、Fable は -- のまま', async ($, on) => {
  const world = engine(on, usageWith([{ kind: 'five_hour', percentUsed: 10 }], 20))
  world.usageBody = fableBody(42)
  await start($)

  expect(world.fetches).toEqual([])
  expect(await band($)).toBe('5h 10% · 7d -- · Fable -- · ctx 20%')
})

test('問い合わせに失敗したときは、直前の Fable の値を残す', async ($, on) => {
  const world = engine(on, usageWith([{ kind: 'five_hour', percentUsed: 10 }], 20))
  world.authorization = { handle: 'h1', kind: 'bearer' }
  world.usageBody = fableBody(42)
  await start($)

  world.usageBody = undefined
  await world.clock.advance(5 * MINUTE)
  expect(world.fetches.length).toBe(2)
  expect(await band($)).toBe('5h 10% · 7d -- · Fable 42% · ctx 20%')
})

test('API の応答 (measure) や 1 分ごとの更新に Fable が無くても、Fable の値を残す', async ($, on) => {
  const world = engine(on, usageWith([{ kind: 'five_hour', percentUsed: 10 }], 20))
  world.authorization = { handle: 'h1', kind: 'bearer' }
  world.usageBody = fableBody(42)
  await start($)

  await $.session.measure({
    context: { window: 200_000, tokens: 60_000, percent: 30 },
    rateLimits: [{ kind: 'five_hour', percentUsed: 12 }],
    changed: ['context', 'rateLimits'],
  })
  expect(await band($)).toBe('5h 12% · 7d -- · Fable 42% · ctx 30%')

  await world.clock.advance(MINUTE)
  expect(await band($)).toMatch(/ · Fable 42% · /)
})
