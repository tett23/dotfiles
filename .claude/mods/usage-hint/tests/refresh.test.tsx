import { expect, mock, test } from 'claude-code/testing'
import type { MockClock } from 'claude-code/testing'
import type { On, RenderSurface, SessionUsage } from 'claude-code'
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
