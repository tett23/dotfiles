import { describe, expect, test } from 'claude-code/testing'

import type { Board } from '../types'
import { EMPTY_BOARD, applyCall, fit, label, listOf } from '../hooks/tasks'

// 完了したタスクを [完了] と表示する一覧の、純粋な処理 (docs/adr/0091)

const created = (board: Board, id: string, subject: string) =>
  applyCall(board, 'TaskCreate', { subject }, { task: { id, subject } })

const two = created(created(EMPTY_BOARD, '1', 'a'), '2', 'b')

describe('applyCall', () => {
  test('TaskCreate は pending の項目を末尾に足す', () => {
    expect(two.tasks).toEqual([
      { id: '1', subject: 'a', status: 'pending' },
      { id: '2', subject: 'b', status: 'pending' },
    ])
  })

  test('TaskUpdate で completed にすると、その項目だけが完了になる', () => {
    const board = applyCall(two, 'TaskUpdate', { taskId: '1', status: 'completed' }, { success: true })

    expect(board.tasks.map(task => task.status)).toEqual(['completed', 'pending'])
  })

  test('TaskUpdate に subject を渡すと件名が変わる', () => {
    const board = applyCall(two, 'TaskUpdate', { taskId: '2', subject: 'c' }, { success: true })

    expect(board.tasks.map(task => task.subject)).toEqual(['a', 'c'])
  })

  test('TaskUpdate で deleted にすると、その項目が消える', () => {
    const board = applyCall(two, 'TaskUpdate', { taskId: '1', status: 'deleted' }, { success: true })

    expect(board.tasks.map(task => task.id)).toEqual(['2'])
  })

  test('知らない taskId の TaskUpdate は一覧を変えない', () => {
    const board = applyCall(two, 'TaskUpdate', { taskId: '9', status: 'completed' }, { success: true })

    expect(board).toEqual(two)
  })

  test('失敗した TaskUpdate は一覧を変えない', () => {
    const board = applyCall(two, 'TaskUpdate', { taskId: '1', status: 'completed' }, { success: false })

    expect(board).toEqual(two)
  })

  test('TaskList の結果で一覧が置き換わる', () => {
    const board = applyCall(two, 'TaskList', {}, {
      tasks: [{ id: '3', subject: 'x', status: 'in_progress', blockedBy: [] }],
    })

    expect(board.tasks).toEqual([{ id: '3', subject: 'x', status: 'in_progress' }])
  })

  test('TodoWrite は TodoWrite の分だけを置き換え、TaskCreate の分を残す', () => {
    const board = applyCall(two, 'TodoWrite', {}, {
      oldTodos: [],
      newTodos: [
        { content: 't1', status: 'completed', activeForm: 'T1' },
        { content: 't2', status: 'pending', activeForm: 'T2' },
      ],
    })

    expect(board.tasks).toEqual(two.tasks)
    expect(board.todos.map(todo => [todo.subject, todo.status])).toEqual([
      ['t1', 'completed'],
      ['t2', 'pending'],
    ])
  })

  test('形の合わない結果とほかのツールは一覧を変えない', () => {
    expect(applyCall(two, 'TaskCreate', {}, { nope: 1 })).toEqual(two)
    expect(applyCall(two, 'TaskList', {}, null)).toEqual(two)
    expect(applyCall(two, 'Bash', { command: 'ls' }, { stdout: '' })).toEqual(two)
  })
})

describe('label', () => {
  test('完了は [完了]、作業中は [作業中]、未着手は [未着手] で始まる', () => {
    expect(label({ id: '1', subject: 'a', status: 'completed' })).toBe('[完了] a')
    expect(label({ id: '1', subject: 'a', status: 'in_progress' })).toBe('[作業中] a')
    expect(label({ id: '1', subject: 'a', status: 'pending' })).toBe('[未着手] a')
  })
})

describe('listOf', () => {
  test('TaskCreate の分、TodoWrite の分の順に並べる', () => {
    const board = applyCall(two, 'TodoWrite', {}, {
      newTodos: [{ content: 't', status: 'pending', activeForm: 'T' }],
    })

    expect(listOf(board).map(task => task.subject)).toEqual(['a', 'b', 't'])
  })
})

describe('fit', () => {
  const list = [
    { id: '1', subject: 'done1', status: 'completed' },
    { id: '2', subject: 'open1', status: 'pending' },
    { id: '3', subject: 'done2', status: 'completed' },
    { id: '4', subject: 'open2', status: 'in_progress' },
    { id: '5', subject: 'done3', status: 'completed' },
  ] as const

  test('入りきるなら全部を出す', () => {
    expect(fit(list, 5)).toEqual({ shown: list, omitted: 0 })
  })

  test('入りきらないとき、未完了をすべて残し、古い完了から省く (省いた数の行も数える)', () => {
    const { shown, omitted } = fit(list, 4)

    expect(shown.map(task => task.subject)).toEqual(['open1', 'open2', 'done3'])
    expect(omitted).toBe(2)
  })

  test('未完了だけでも入りきらないときは、古い未完了も省く', () => {
    const { shown, omitted } = fit(list, 2)

    expect(shown.map(task => task.subject)).toEqual(['open2'])
    expect(omitted).toBe(4)
  })
})
