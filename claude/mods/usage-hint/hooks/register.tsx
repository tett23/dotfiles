import { atom, read, update } from 'claude-code'
import type { Register, SessionContextUsage, SessionRateLimit } from 'claude-code'

import type { Snapshot } from '../types'
import { formatUsage } from './format'

const EMPTY: Snapshot = { contextPercent: null, rateLimits: [] }

const snapshot = atom({ plugin: 'usage-hint', key: 'snapshot' } as const, EMPTY)

const toSnapshot = (
  context: SessionContextUsage,
  rateLimits: readonly SessionRateLimit[],
): Snapshot => ({
  contextPercent: context.percent ?? null,
  rateLimits: rateLimits.map(({ kind, percentUsed, resetsAt }) => ({
    kind,
    percentUsed,
    resetsAt,
  })),
})

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'usage-hint',
      description: 'usage-hint が受け取ったレートリミット窓をそのまま表示する',
    })

    const result = await next(e)
    const usage = await $.session.usage().catch(() => undefined)
    if (usage) {
      await update($, snapshot, () => toSnapshot(usage.context, usage.rateLimits))
    }

    return result
  })

  on('session.measure', async ($, e, next) => {
    await update($, snapshot, () => toSnapshot(e.context, e.rateLimits))

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

  // terminal: 入力欄の下のヒント行に tail で追記する (既存のピルは残る)
  on('ui.render', { component: 'PromptHint' }, async ($, e, next) => {
    if (e.surface !== 'terminal') {
      return next(e)
    }
    const tail = formatUsage(await read($, snapshot))

    return next({ ...e, props: { ...e.props, tail } })
  })

  // desktop は PromptHint を描かないため、入力欄のすぐ上の帯に出す (docs/adr/0004)
  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.surface === 'terminal' || e.props.hasSurvey) {
      return next(e)
    }
    const { Text } = $.ui.resolve(e)

    return <Text dimColor>{formatUsage(await read($, snapshot))}</Text>
  })
}
