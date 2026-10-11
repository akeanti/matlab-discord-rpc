// What drpc puts on Discord in each situation. Same wording as drpc.m.
import editing from '../../../assets/icons/editing.png'
import running from '../../../assets/icons/running.png'
import debug from '../../../assets/icons/debug.png'
import simulink from '../../../assets/icons/simulink.png'
import app from '../../../assets/icons/app.png'
import plot from '../../../assets/icons/plot.png'
import idle from '../../../assets/icons/idle.png'

export interface PresenceState {
  id: string
  /** chip label */
  short: string
  /** "When you're ..." */
  when: string
  details: string
  state?: string
  icon?: string
  /** hover text on the small icon */
  hover?: string
  /** elapsed seconds when the page opens */
  elapsed: number
}

const SEP = ' · '

export const states: PresenceState[] = [
  {
    id: 'edit',
    short: 'Editing',
    when: 'typing in the Editor',
    details: 'Editing pid_controller.m',
    state: ['Function', 'Line 42 of 142', 'unsaved'].join(SEP),
    icon: editing,
    hover: 'Folder: lab3 · 4 files open',
    elapsed: 4324
  },
  {
    id: 'run',
    short: 'Running',
    when: 'running code',
    details: 'Running sweep_bode.m',
    state: 'Folder: lab3',
    icon: running,
    hover: 'MATLAB is busy',
    elapsed: 207
  },
  {
    id: 'debug',
    short: 'Debugging',
    when: 'stopped at a breakpoint',
    details: 'Debugging kalman_step.m',
    state: 'Paused at line 87',
    icon: debug,
    hover: 'Folder: estimation',
    elapsed: 370
  },
  {
    id: 'sim',
    short: 'Simulating',
    when: 'running a Simulink model',
    details: 'Simulating motor_model',
    state: ['Simulink', '45% done'].join(SEP),
    icon: simulink,
    hover: 'Folder: drives',
    elapsed: 51
  },
  {
    id: 'build',
    short: 'Building',
    when: 'in a Simulink window',
    details: 'Building motor_model',
    state: ['Simulink', '48 blocks'].join(SEP),
    icon: simulink,
    hover: 'Folder: drives',
    elapsed: 1360
  },
  {
    id: 'app',
    short: 'Designing',
    when: 'in App Designer',
    details: 'Designing scope_ui.mlapp',
    state: 'App Designer',
    icon: app,
    hover: 'Folder: gui',
    elapsed: 1473
  },
  {
    id: 'plot',
    short: 'Plots',
    when: 'looking at a figure',
    details: 'Viewing Figure 2: Bode Plot',
    state: '3 figures open',
    icon: plot,
    hover: 'Folder: lab3',
    elapsed: 6012
  },
  {
    id: 'cmd',
    short: 'Command Window',
    when: 'in the Command Window',
    details: 'In the Command Window',
    state: ['Folder: lab3', '14 variables'].join(SEP),
    elapsed: 7519
  },
  {
    id: 'idle',
    short: 'Away',
    when: 'gone for 10 minutes',
    details: 'Away from keyboard',
    state: 'Last on pid_controller.m',
    icon: idle,
    hover: 'Idle',
    elapsed: 723
  }
]

/** Discord's elapsed format: 03:27, 1:12:04 */
export function elapsedText(s: number): string {
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  const sec = Math.floor(s % 60)
  const pad = (n: number) => String(n).padStart(2, '0')
  return h > 0 ? `${h}:${pad(m)}:${pad(sec)}` : `${pad(m)}:${pad(sec)}`
}
