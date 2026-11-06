import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Task } from '../types'
import { EMPTY_BOARD, applyCall, fit, label, listOf } from './tasks'

// タスクの一覧をペインに出し、完了した項目に [完了] と付ける。デスクトップアプリ専用 (docs/adr/0091)

const PANE = 'task-marks'
const TITLE = 'タスク'
const TOOLS = ['TaskCreate', 'TaskUpdate', 'TaskList', 'TodoWrite']

// Board の形を変えたらタグを変える (前の版が $.state に残した値を読まないようにする)
const board = atom({ plugin: 'task-marks', key: 'board' } as const, EMPTY_BOARD, { shape: 'board-1' })
const isOpened = atom({ plugin: 'task-marks', key: 'isOpened' } as const, false)

const onDesktop = async ($: EngineInterface): Promise<boolean> =>
  (await $.session.surfaces()).includes('desktop')

const open = async ($: EngineInterface): Promise<void> => {
  await update($, isOpened, () => true)
  await $.ui.open({ id: PANE, title: TITLE })
}

const STYLES = {
  completed: { color: 'success', bold: true },
  in_progress: {},
  pending: { dimColor: true },
} as const

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'task-marks', description: 'タスクの一覧のペインを開く' })

    return next(e)
  })

  on('command.run', { command: 'task-marks' }, async $ => {
    if (!(await onDesktop($))) return { text: 'task-marks のペインはデスクトップアプリでだけ開けます。' }
    await open($)

    return { text: 'タスクの一覧のペインを開きました。' }
  })

  on('tool.call', async ($, e, next) => {
    const ran = await next(e)
    if (!TOOLS.includes(e.tool) || 'deny' in ran || ran.isError) return ran
    const { tool, tool_use_id: _id, ...input } = e as unknown as Record<string, unknown>
    await update($, board, current => applyCall(current, String(tool), input, ran.result))
    if (e.tool === 'TaskCreate' && !(await read($, isOpened)) && (await onDesktop($))) await open($)

    return ran
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e, next) => {
    if (e.surface !== 'desktop') return next(e)
    const { Box, Text } = $.ui.resolve(e)
    const list = listOf(await read($, board))
    const { shown, omitted } = fit(list, Math.max(1, e.props.scroll.bodyRows))
    const row = (task: Task) => <Text {...STYLES[task.status]}>{label(task)}</Text>

    return (
      <Box flexDirection="column">
        {list.length === 0 && <Text dimColor>タスクはありません</Text>}
        {shown.map(row)}
        {omitted > 0 && <Text dimColor>{`ほかに ${omitted} 件`}</Text>}
      </Box>
    )
  })
}
