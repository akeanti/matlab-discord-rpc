# Configuration

Settings live in `config.json` next to `drpc.m`. Open it with:

```matlab
drpc config
```

Changes apply within 2 seconds of saving. No restart needed. Keys you leave out fall back to the defaults below, and `drpc update` never touches this file.

| Key | Default | What it does |
|---|---|---|
| `client_id` | shared MATLAB app | Discord application id. Must be a string in quotes. See [using your own Discord app](own-discord-app.md) |
| `show_names` | `true` | `false` shows "Editing a function" instead of the file name. Same as `drpc names off` |
| `show_line` | `true` | Cursor line, e.g. "Line 42 of 142" |
| `show_folder` | `true` | Current folder name in the Command Window state and hover text |
| `hidden_folders` | `[]` | If the current folder or the open file's path contains any of these, names and folder are hidden |
| `idle_minutes` | `10` | Minutes without keyboard or mouse input before "Away from keyboard". `0` turns it off |
| `detect_running` | `true` | Show "Running ..." while code runs |
| `busy_cpu_percent` | `60` | MATLAB CPU use (percent of one core) that counts as running while MATLAB still answers |
| `timer` | `"session"` | `"session"` counts from when MATLAB opened. `"activity"` restarts on every file or mode change |
| `member_list` | `"name"` | What shows under your name in member lists: `"name"` (Playing MATLAB), `"details"` or `"state"` |
| `buttons` | `[]` | Up to two buttons. Other people can click them, you can't |
| `images` | shared icons | One image per state. An `https://` URL or an art asset key from your own app. `""` hides that icon |

## Examples

Hide names for anything under a folder called `Internship` or `Exam`:

```json
"hidden_folders": ["Internship", "Exam"]
```

Add buttons:

```json
"buttons": [
  { "label": "GitHub", "url": "https://github.com/you" },
  { "label": "Portfolio", "url": "https://you.dev" }
]
```

Show the file you are editing right in the member list:

```json
"member_list": "details"
```

Use your own pictures. Any square PNG reachable over https works:

```json
"images": {
  "matlab": "https://example.com/my-logo.png",
  "editing": "https://example.com/pencil.png",
  "idle": ""
}
```

The image keys are `matlab` (the big picture), `editing`, `running`, `debug`, `simulink`, `app`, `plot` and `idle`.
