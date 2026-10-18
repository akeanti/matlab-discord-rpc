# Commands

Everything goes through one function, `drpc`. Type a command in the Command Window, or click the links that `drpc` prints.

| Command | What it does |
|---|---|
| `drpc` | Status, with clickable actions |
| `drpc pause` | Hide your status for this session |
| `drpc resume` | Show it again |
| `drpc names off` | Say "Editing a function" instead of the file name. `drpc names on` brings names back |
| `drpc config` | Open `config.json`. Changes apply as soon as you save |
| `drpc preview` | The exact payload sent to Discord, plus diagnostics |
| `drpc restart` | Reload everything and reconnect |
| `drpc stop` | Stop and clear your Discord status |
| `drpc start` | Start it. `startup.m` does this for you when MATLAB opens |
| `drpc setup` | Make it start with MATLAB (adds a marked block to `startup.m`) |
| `drpc update` | Install the newest release from GitHub |
| `drpc uninstall` | Stop it and take it out of `startup.m` |
| `drpc docs` | Open this site |
| `drpc version` | Print the version |

`help drpc` prints the same list inside MATLAB.

## drpc

```text
>> drpc

  Discord Rich Presence for MATLAB  v1.2.0

  Discord       Connected as you
  Showing       Editing pid_controller.m
                Function · Line 42 of 142
  Settings      config.json  (names on, idle after 10 min)

  pause   hide names   preview   restart   stop   docs
```

| Line | Meaning |
|---|---|
| **Discord** | What the bridge is doing: `Connected as ...`, `Connecting`, `Discord is not running`, `Paused`, ... |
| **Showing** | What your profile shows right now |
| **Discord said** | Discord rejected the last update, and why. Usually a broken image URL or button |
| **Settings** | Your `config.json`, and its error if it has one |

When MATLAB is busy and the watchdog is showing "Running", `drpc` says so under **Showing**.

## drpc pause

Clears your status until you run `drpc resume` or restart MATLAB. drpc keeps running in the background, so resuming is instant.

## drpc names

```matlab
drpc names off   % "Editing a function", "Simulating a model", "Designing an app"
drpc names on
drpc names       % toggle
```

This sets `show_names` in `config.json`, so it sticks across restarts. Only that one line of the file changes. To hide names for some projects only, use [`hidden_folders`](./configuration#hidden-folders) instead.

## drpc preview

Prints the activity drpc would send right now, the ready-made "Running" activity the watchdog uses while MATLAB is busy, and live diagnostics:

```text
Diagnostics
  Discord       Connected as you
  Updates sent  37
  Window        matlab / main  "MATLAB R2024a - academic use"
  Focus         editor  (com.mathworks.widgets.SyntaxTextPane)
  Debugging     off
  MATLAB CPU    3% of one core
  Idle          2 s
  Bridge        v1.2.0, pid 13368
```

Paste this when you [open an issue](https://github.com/akeanti/matlab-discord-rpc/issues/new/choose). Remove anything you don't want public first.

## drpc update

Asks GitHub for the newest release and compares it with yours. If yours is current, it says so and stops. Otherwise it downloads that release and runs its installer, which keeps your `config.json`.

If GitHub's release list can't be reached, it installs the latest code from the `main` branch instead.

## drpc setup and drpc uninstall

`drpc setup` writes this block at the end of `startup.m` in your MATLAB user folder:

```matlab
% >>> MATLAB Discord RPC >>>
try
    addpath(fullfile(fileparts(mfilename('fullpath')), 'DiscordRPC'));
    drpc autostart
catch drpcErr
    warning('Discord RPC: %s', drpcErr.message);
end
clear drpcErr
% <<< MATLAB Discord RPC <<<
```

Running it again replaces the block instead of adding a second one. `drpc uninstall` removes exactly that block and leaves the rest of your `startup.m` alone.

`drpc autostart` waits a few seconds for the desktop, then starts drpc. In `-batch` jobs, parallel workers, MATLAB Engine sessions and `-nodesktop` it does nothing.
