export type Limit = { kind: string; percentUsed: number; resetsAt?: string }

export type Snapshot = {
  contextPercent: number | null
  rateLimits: Limit[]
}

declare module 'claude-code' {
  interface PluginState {
    'usage-hint': { snapshot: Snapshot }
  }
}
