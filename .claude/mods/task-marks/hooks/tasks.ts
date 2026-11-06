import type { Board, Status, Task } from '../types'

// タスクの呼び出しから一覧を組み立て、ペインの行にする純粋な処理 (docs/adr/0091)

export const EMPTY_BOARD: Board = { tasks: [], todos: [] }

const STATUSES: readonly Status[] = ['pending', 'in_progress', 'completed']

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null

const isStatus = (value: unknown): value is Status => STATUSES.includes(value as Status)

const isString = (value: unknown): value is string => typeof value === 'string'

const taskOf = (value: unknown): Task | undefined =>
  isRecord(value) && isString(value.id) && isString(value.subject) && isStatus(value.status)
    ? { id: value.id, subject: value.subject, status: value.status }
    : undefined

const todoOf = (value: unknown, index: number): Task | undefined =>
  isRecord(value) && isString(value.content) && isStatus(value.status)
    ? { id: `todo-${index}`, subject: value.content, status: value.status }
    : undefined

const defined = <T>(values: readonly (T | undefined)[]): T[] =>
  values.filter((value): value is T => value !== undefined)

const created = (board: Board, result: unknown): Board => {
  const task = isRecord(result) && isRecord(result.task) ? result.task : undefined
  if (!task || !isString(task.id) || !isString(task.subject)) return board

  return { ...board, tasks: [...board.tasks, { id: task.id, subject: task.subject, status: 'pending' }] }
}

const updated = (board: Board, input: Record<string, unknown>, result: unknown): Board => {
  if (!isRecord(result) || result.success !== true || !isString(input.taskId)) return board
  const { taskId, status, subject } = input
  if (!board.tasks.some(task => task.id === taskId)) return board
  if (status === 'deleted') return { ...board, tasks: board.tasks.filter(task => task.id !== taskId) }

  return {
    ...board,
    tasks: board.tasks.map(task =>
      task.id === taskId
        ? {
            ...task,
            ...(isStatus(status) ? { status } : {}),
            ...(isString(subject) ? { subject } : {}),
          }
        : task,
    ),
  }
}

const listed = (board: Board, result: unknown): Board =>
  isRecord(result) && Array.isArray(result.tasks)
    ? { ...board, tasks: defined(result.tasks.map(taskOf)) }
    : board

const todosWritten = (board: Board, result: unknown): Board =>
  isRecord(result) && Array.isArray(result.newTodos)
    ? { ...board, todos: defined(result.newTodos.map(todoOf)) }
    : board

// エラーでない呼び出しの入力と結果を、一覧に反映する。知らない形のものは無視する
export const applyCall = (
  board: Board,
  tool: string,
  input: Record<string, unknown>,
  result: unknown,
): Board => {
  switch (tool) {
    case 'TaskCreate':
      return created(board, result)
    case 'TaskUpdate':
      return updated(board, input, result)
    case 'TaskList':
      return listed(board, result)
    case 'TodoWrite':
      return todosWritten(board, result)
    default:
      return board
  }
}

export const listOf = (board: Board): Task[] => [...board.tasks, ...board.todos]

const MARKS: Record<Status, string> = {
  completed: '[完了]',
  in_progress: '[作業中]',
  pending: '[未着手]',
}

export const label = (task: Task): string => `${MARKS[task.status]} ${task.subject}`

// room 行に収める。省くときは「省いた数」の行に 1 行を使う。古い完了の項目から省き、
// それでも入らなければ古い未完了の項目も省く
export const fit = (
  list: readonly Task[],
  room: number,
): { shown: readonly Task[]; omitted: number } => {
  if (list.length <= room) return { shown: list, omitted: 0 }
  const keep = Math.max(0, room - 1)
  const dropOrder = [
    ...list.filter(task => task.status === 'completed'),
    ...list.filter(task => task.status !== 'completed'),
  ]
  const dropped = new Set(dropOrder.slice(0, list.length - keep))

  return { shown: list.filter(task => !dropped.has(task)), omitted: dropped.size }
}
