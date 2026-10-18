# Configuration

Settings live in `config.json` next to `drpc.m`. Open it with:

```matlab
drpc config
```

Changes apply within 2 seconds of saving. No restart needed. Keys you leave out fall back to the defaults below, and `drpc update` never touches this file.

A new `config.json` holds the settings you're most likely to change. `client_id` and `images` stay out of it, so they keep following the defaults until you add them yourself.

> [!NOTE]
> If you save the file with a JSON error, drpc prints what's wrong and keeps your previous settings until you fix it. `drpc` shows the error under **Settings** too.

## All keys

| Key | Default | What it does |
|---|---|---|
| `client_id` | shared MATLAB app | Discord application id. Must be a string in quotes. See [your own Discord app](./own-discord-app) |
| `show_names` | `true` | `false` shows "Editing a function" instead of the file name. Same as `drpc names off` |
| `show_line` | `true` | Cursor line, e.g. "Line 42 of 142" |
| `show_folder` | `true` | Current folder name in the Command Window state and hover text |
| `hidden_folders` | `[]` | If the path of the current folder, the open file, the Simulink model or the App Designer app contains any of these, names and folder are hidden |
| `idle_minutes` | `10` | Minutes without keyboard or mouse input before "Away from keyboard". `0` turns it off |
| `detect_running` | `true` | Show "Running ..." while code runs |
| `busy_cpu_percent` | `60` | MATLAB CPU use (percent of one core) that counts as running while MATLAB still answers |
| `timer` | `"session"` | `"session"` counts from when MATLAB opened. `"activity"` restarts on every file or mode change |
| `member_list` | `"name"` | What shows under your name in member lists: `"name"` (Playing MATLAB), `"details"` or `"state"` |
| `buttons` | `[]` | Up to two buttons. Other people can click them, you can't |
| `images` | shared icons | One image per state. An `https://` URL or an art asset key from your own app. `""` hides that icon |

## Examples

### Hidden folders

Hide names for anything under a folder called `Internship` or `Exam`:

```json
"hidden_folders": ["Internship", "Exam"]
```

Matching ignores case and works on any part of the path. More ways to stay private are on the [Privacy](./privacy) page.

### Buttons

```json
"buttons": [
  { "label": "GitHub", "url": "https://github.com/you" },
  { "label": "Portfolio", "url": "https://you.dev" }
]
```

Labels are cut to 32 characters. URLs must start with `http://` or `https://` and be at most 512 characters. Discord doesn't show your own buttons to you, so ask a friend to check.

### Member list

Show the file you are editing right in the member list, instead of "Playing MATLAB":

```json
"member_list": "details"
```

### Timer

Restart the elapsed time every time you switch file or mode, instead of counting from when MATLAB opened:

```json
"timer": "activity"
```

Running code, simulations and "Away" always count from when they started.

### Images

Use your own pictures. Any square PNG reachable over https works:

```json
"images": {
  "matlab": "https://example.com/my-logo.png",
  "editing": "https://example.com/pencil.png",
  "idle": ""
}
```

The image keys are `matlab` (the big picture), `editing`, `running`, `debug`, `simulink`, `app`, `plot` and `idle`. Keys you leave out keep the default icon.

## A full example

```json
{
  "show_names": true,
  "show_line": true,
  "show_folder": true,
  "hidden_folders": ["Internship"],
  "idle_minutes": 10,
  "detect_running": true,
  "busy_cpu_percent": 60,
  "timer": "session",
  "member_list": "name",
  "buttons": [{ "label": "GitHub", "url": "https://github.com/you" }]
}
```
