import { expect, test } from 'claude-code/testing'
import type { On } from 'claude-code'
import type { Engine } from 'claude-code/testing'

const TEXT = '5h 23% · 7d 41% · Fable 12% · ctx 37%'

const measure = async ($: Engine, on: On) => {
  on('session.measure', ($, e) => ({ changed: e.changed }))
  await $.session.measure({
    context: { window: 200000, tokens: 74000, percent: 37 },
    rateLimits: [
      { kind: 'five_hour', percentUsed: 23 },
      { kind: 'seven_day', percentUsed: 41 },
      { kind: 'seven_day_overage_included', percentUsed: 12 },
    ],
    changed: ['context', 'rateLimits'],
  })
}

// エンジン自身のヒント行の代わり: 受け取った hint と tail をそのまま描く
const engineHint = (on: On) =>
  on('ui.render', { component: 'PromptHint' }, ($, e) => {
    const { Text } = $.ui.resolve(e)

    return <Text>{`${e.props.hint}|${e.props.tail ?? ''}`}</Text>
  })

// エンジン自身の AbovePrompt: 何も描かない
const engineBand = (on: On) =>
  on('ui.render', { component: 'AbovePrompt' }, ($, e) => {
    const { Box } = $.ui.resolve(e)

    return <Box />
  })

const BAND_PROPS = {
  hasSurvey: false,
  isWorking: false,
  maxRows: 10,
  bodyColumns: 80,
} as const

test('terminal: 入力欄の下のヒント行の末尾に追記する', async ($, on) => {
  engineHint(on)
  await measure($, on)
  const ui = await $.ui.mount({
    plugin: 'usage-hint',
    surface: 'terminal',
    component: 'PromptHint',
    props: { isDraft: false, isWorking: false, hint: '? for shortcuts' },
  })

  expect(await ui.find({ type: 'Text', text: `? for shortcuts|${TEXT}` })).toBeDefined()
})

test('terminal: 入力欄の上の帯には出さない', async ($, on) => {
  engineBand(on)
  await measure($, on)
  const ui = await $.ui.mount({
    plugin: 'usage-hint',
    surface: 'terminal',
    component: 'AbovePrompt',
    props: BAND_PROPS,
  })

  expect(await ui.find({ text: TEXT })).toBeUndefined()
})

test('desktop: PromptHint を描かないので入力欄のすぐ上の帯に出す', async ($, on) => {
  engineBand(on)
  await measure($, on)
  const ui = await $.ui.mount({
    plugin: 'usage-hint',
    surface: 'desktop',
    component: 'AbovePrompt',
    props: BAND_PROPS,
  })

  expect(await ui.find({ type: 'Text', text: TEXT })).toBeDefined()
})

test('desktop: アンケート表示中は帯を譲る', async ($, on) => {
  engineBand(on)
  await measure($, on)
  const ui = await $.ui.mount({
    plugin: 'usage-hint',
    surface: 'desktop',
    component: 'AbovePrompt',
    props: { ...BAND_PROPS, hasSurvey: true },
  })

  expect(await ui.find({ text: TEXT })).toBeUndefined()
})
