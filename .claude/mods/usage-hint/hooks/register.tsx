import { atom, read, update } from 'claude-code'
import type {
  ElementConstructor,
  EngineInterface,
  Register,
  RenderElement,
  SessionRateLimit,
  TextProps,
  Timer,
} from 'claude-code'

import type { Limit, Snapshot } from '../types'
import type { Level, Segment } from './format'
import {
  SEPARATOR,
  estimatePercent,
  fableFromUsage,
  keepFable,
  parseLimits,
  restoreLimits,
  usageSegments,
  withLimit,
} from './format'

const EMPTY: Snapshot = { contextPercent: null, rateLimits: [] }

const snapshot = atom({ plugin: 'usage-hint', key: 'snapshot' } as const, EMPTY)

const STORE_KEY = 'rateLimits'

const toLimits = (rateLimits: readonly SessionRateLimit[]): Limit[] =>
  rateLimits.map(({ kind, percentUsed, resetsAt }) => ({ kind, percentUsed, resetsAt }))

// 最初の API 応答の前は、窓を前回保存した値から、コンテキストをローカルの推定から作る
// (docs/adr/0008)
const initialSnapshot = async ($: EngineInterface): Promise<Snapshot> => {
  const { context, rateLimits } = await $.session.usage()
  const contextPercent =
    context.percent ??
    (await $.session
      .usage({ breakdown: 'summary' })
      .then(({ context: estimated }) =>
        estimated.breakdown
          ? estimatePercent(estimated.breakdown.totalTokens, estimated.window)
          : null,
      )
      .catch(() => null))
  const limits =
    rateLimits.length > 0
      ? toLimits(rateLimits)
      : restoreLimits(parseLimits(await $.store.get(STORE_KEY)), await $.clock.now())

  return { contextPercent, rateLimits: limits }
}

// 表示の値を session.usage() から作りなおす。窓が空なら直前の窓を使い、どちらもリセット時刻を
// 過ぎた窓は 0% にする。読み取りに失敗したときは直前の表示を残す。保存はしない (docs/adr/0063)
const refresh = async ($: EngineInterface): Promise<void> => {
  const usage = await $.session.usage().catch(() => undefined)
  if (!usage) {
    return
  }
  const now = await $.clock.now()
  await update($, snapshot, previous => ({
    contextPercent: usage.context.percent ?? previous.contextPercent,
    rateLimits: restoreLimits(
      usage.rateLimits.length > 0
        ? keepFable(toLimits(usage.rateLimits), previous.rateLimits)
        : previous.rateLimits,
      now,
    ),
  }))
}

// Claude Code の /usage と同じ使用量の API。Fable の週のウィンドウは、API の応答 (session.measure) には
// Fable にリクエストしたときしか入らないので、ここから取る (docs/adr/0074)
const USAGE_URL = 'https://api.anthropic.com/api/oauth/usage'

const parseJson = (text: string): unknown => {
  try {
    return JSON.parse(text)
  } catch {
    return undefined
  }
}

// 使用量の API から Fable のウィンドウを取り、表示と保存に反映する。認証の handle が無い・失敗・形が違うときは何もしない
const refreshFable = async ($: EngineInterface): Promise<void> => {
  const authorization = await $.session.authorize().catch(() => null)
  if (!authorization) {
    return
  }
  const response = await $.http
    .fetch(USAGE_URL, { auth: authorization.handle })
    .catch(() => undefined)
  const fable = response?.ok ? fableFromUsage(parseJson(response.text)) : undefined
  if (!fable) {
    return
  }
  const now = await $.clock.now()
  await update($, snapshot, previous => ({
    ...previous,
    rateLimits: restoreLimits(withLimit(previous.rateLimits, fable), now),
  }))
  await $.store.set(STORE_KEY, (await read($, snapshot)).rateLimits)
}

const REFRESH_INTERVAL_MS = 60_000
// 使用量の API は、1 分ごとの更新の 5 回に 1 回 (5 分ごと) だけ問い合わせる (docs/adr/0074)
const FABLE_EVERY = 5

// 1 分ごとの更新。どの画面も表示していない間は更新しない (docs/adr/0063)
const refreshIfShown = async ($: EngineInterface, withFable: boolean): Promise<void> => {
  const surfaces = await $.session.surfaces().catch(() => [])
  if (surfaces.length > 0) {
    await refresh($)
    if (withFable) {
      await refreshFable($)
    }
  }
}

let refreshTimer: Timer | undefined
let refreshTicks = 0

const stopRefresh = () => {
  refreshTimer?.cancel()
  refreshTimer = undefined
}

// warning は暗めの黄色、danger は暗めの赤、それ以外は dim (docs/adr/0005, 0060)。ラベルは太字 (docs/adr/0006)
const LEVEL_PROPS: Record<Level, TextProps> = {
  normal: { dimColor: true },
  warning: { color: '#b39020' },
  danger: { color: '#b5403a' },
}

const toText =
  (Text: ElementConstructor<TextProps>) =>
  ({ label, value, level }: Segment): RenderElement => (
    <Text {...LEVEL_PROPS[level]}>
      <Text bold>{label}</Text>
      {` ${value}`}
    </Text>
  )

const interleave = <T,>(items: readonly T[], separator: T): T[] =>
  items.flatMap((item, index) => (index === 0 ? [item] : [separator, item]))

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'usage-hint',
      description: 'usage-hint が受け取ったレートリミット窓をそのまま表示する',
    })

    const result = await next(e)
    const initial = await initialSnapshot($).catch(() => undefined)
    if (initial) {
      await update($, snapshot, () => initial)
    }
    await refresh($)
    await refreshFable($)
    stopRefresh()
    refreshTicks = 0
    refreshTimer = $.clock.every(REFRESH_INTERVAL_MS, () => {
      refreshTicks += 1
      void refreshIfShown($, refreshTicks % FABLE_EVERY === 0)
    })

    return result
  })

  // /clear は会話が終わるだけで、同じプロセスで次の会話が続き session.start は来ないので止めない (docs/adr/0065)
  on('session.end', async ($, e, next) => {
    if (e.reason !== 'clear') {
      stopRefresh()
    }

    return next(e)
  })

  on('session.measure', async ($, e, next) => {
    // 窓が空の報告では直前の窓を残す (docs/adr/0008)。Fable が無ければ直前の Fable を残す (docs/adr/0074)
    const previous = await read($, snapshot)
    const rateLimits =
      e.rateLimits.length > 0
        ? keepFable(toLimits(e.rateLimits), previous.rateLimits)
        : previous.rateLimits
    if (e.rateLimits.length > 0) {
      await $.store.set(STORE_KEY, rateLimits)
    }
    await update($, snapshot, () => ({
      contextPercent: e.context.percent ?? null,
      rateLimits,
    }))

    return next(e)
  })

  on('command.run', { command: 'usage-hint' }, async $ => {
    const { rateLimits, contextPercent } = await read($, snapshot)
    const rows = rateLimits.map(
      ({ kind, percentUsed, resetsAt }) =>
        `- ${kind}: ${percentUsed}%${resetsAt ? ` (reset ${resetsAt})` : ''}`,
    )

    return {
      text: [
        `context: ${contextPercent ?? '--'}%`,
        rows.length === 0 ? 'rateLimits: (まだ受信していません)' : 'rateLimits:',
        ...rows,
      ].join('\n'),
    }
  })

  // terminal: 項目ごとに色を付けるため tail ではなくヒント行ごと描く (docs/adr/0005)
  on('ui.render', { component: 'PromptHint' }, async ($, e, next) => {
    if (e.surface !== 'terminal') {
      return next(e)
    }
    const { Box, Text } = $.ui.resolve(e)
    const segments = usageSegments(await read($, snapshot))
    const hint = e.props.hint === '' ? [] : [<Text dimColor>{e.props.hint}</Text>]

    return (
      <Box flexDirection="row">
        {interleave([...hint, ...segments.map(toText(Text))], <Text dimColor>{SEPARATOR}</Text>)}
      </Box>
    )
  })

  // desktop は PromptHint を描かないため、入力欄のすぐ上の帯に出す (docs/adr/0004)
  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.surface === 'terminal' || e.props.hasSurvey) {
      return next(e)
    }
    const { Box, Text } = $.ui.resolve(e)
    const segments = usageSegments(await read($, snapshot))

    return (
      <Box flexDirection="row">
        {interleave(segments.map(toText(Text)), <Text dimColor>{SEPARATOR}</Text>)}
      </Box>
    )
  })
}
