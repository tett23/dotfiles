import { expect, test } from 'claude-code/testing'
import type { On, RenderSurface } from 'claude-code'
import type { Engine } from 'claude-code/testing'

// task-marks の hook (docs/adr/0091)

const PANE = {
  plugin: 'task-marks',
  component: 'Pane',
  requestId: 'task-marks',
  props: {
    title: 'タスク',
    isFocused: false,
    bodyColumns: 60,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 20 },
    view: {},
  },
} as const

type World = { opens: string[]; isError: boolean }

// エンジン側: TaskCreate は呼ばれた順に id を振り、TaskUpdate は成功を返す
const engine = (on: On, surfaces: readonly RenderSurface[] = ['desktop']): World => {
  const world: World = { opens: [], isError: false }
  let next = 0
  on('command.register', ($, e) => ({ value: { command: e.name } }))
  on('session.start', ($, e) => ({ cwd: e.cwd }))
  on('session.surfaces', () => ({ value: surfaces }))
  on('ui.open', ($, e) => {
    world.opens.push(e.id)

    return { value: { isPlaced: true } }
  })
  on('tool.call', ($, e) => {
    const result =
      e.tool === 'TaskCreate'
        ? { task: { id: String((next += 1)), subject: e.subject } }
        : { success: true, taskId: e.tool === 'TaskUpdate' ? e.taskId : '', updatedFields: ['status'] }

    return world.isError ? { result, isError: true } : { result }
  })

  return world
}

const RUN = {
  command: 'task-marks',
  args: '',
  origin: { kind: 'composer' },
  presentation: { isFullscreen: false, columns: 80 },
} as const

const start = ($: Engine, surface: RenderSurface = 'desktop') =>
  $.session.start({ cwd: '/', surface, isInteractive: true })

const texts = async ($: Engine) => {
  const ui = await $.ui.mount({ ...PANE, surface: 'desktop' })
  const found = await ui.findAll({ type: 'Text' })
  await ui.unmount()

  return found
}

test('完了にしたタスクは、緑の太字の [完了] 件名 で出る', async ($, on) => {
  engine(on)
  await start($)
  await $.tool.call({ tool: 'TaskCreate', subject: 'テストを書く', description: '' })
  await $.tool.call({ tool: 'TaskCreate', subject: '実装する', description: '' })
  await $.tool.call({ tool: 'TaskUpdate', taskId: '1', status: 'completed' })

  const found = await texts($)
  const done = found.find(text => text.text === '[完了] テストを書く')
  expect(done?.props.bold).toBe(true)
  expect(done?.props.color).toBe('success')
  const open = found.find(text => text.text === '[未着手] 実装する')
  expect(open?.props.dimColor).toBe(true)
})

test('エラーの結果は反映しない', async ($, on) => {
  const world = engine(on)
  await start($)
  world.isError = true
  await $.tool.call({ tool: 'TaskCreate', subject: 'a', description: '' })

  expect((await texts($)).map(text => text.text)).toEqual(['タスクはありません'])
})

test('desktop では、最初の TaskCreate でペインを一度だけ開く', async ($, on) => {
  const world = engine(on)
  await start($)
  expect(world.opens).toEqual([])
  await $.tool.call({ tool: 'TaskCreate', subject: 'a', description: '' })
  await $.tool.call({ tool: 'TaskCreate', subject: 'b', description: '' })

  expect(world.opens).toEqual(['task-marks'])
})

test('terminal だけなら、TaskCreate でペインを開かない', async ($, on) => {
  const world = engine(on, ['terminal'])
  await start($, 'terminal')
  await $.tool.call({ tool: 'TaskCreate', subject: 'a', description: '' })

  expect(world.opens).toEqual([])
})

test('desktop では /task-marks でペインが開く', async ($, on) => {
  const world = engine(on)
  await start($)
  await $.command.run(RUN)

  expect(world.opens).toEqual(['task-marks'])
})

test('terminal だけなら /task-marks で開かず、その旨を返す', async ($, on) => {
  const world = engine(on, ['terminal'])
  await start($, 'terminal')
  const { text } = await $.command.run(RUN)

  expect(world.opens).toEqual([])
  expect(text).toContain('デスクトップアプリ')
})

test('terminal の面には描かない', async ($, on) => {
  engine(on, ['terminal'])
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)

    return <Text>engine</Text>
  })
  await start($, 'terminal')
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })

  expect((await ui.find({ type: 'Text' }))?.text).toBe('engine')
  await ui.unmount()
})
