export type Status = 'pending' | 'in_progress' | 'completed'

export type Task = { id: string; subject: string; status: Status }

// tasks は TaskCreate・TaskUpdate・TaskList の分、todos は TodoWrite の分 (docs/adr/0091)
export type Board = { tasks: Task[]; todos: Task[] }

declare module 'claude-code' {
  interface PluginState {
    'task-marks': { board: Shaped<Board>; isOpened: boolean }
  }
}
