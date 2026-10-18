# Getting started

drpc puts what you're doing in MATLAB on your Discord profile: the file you're editing, the script that's running, the breakpoint you're stuck on, the Simulink model that's simulating. It runs inside MATLAB and starts with it.

## What you need

| You need | Why |
|---|---|
| Windows 10 or 11 | drpc builds its Discord bridge with the C# compiler that is part of Windows |
| The Discord desktop app | Discord in a browser can't receive Rich Presence |
| MATLAB R2021a or newer | tested on R2024a. Simulink is optional |

No Python, no toolboxes, no admin rights.

## Install

Paste this into the MATLAB Command Window:

```matlab
unzip("https://github.com/akeanti/matlab-discord-rpc/archive/refs/heads/main.zip", tempdir); run(fullfile(tempdir, "matlab-discord-rpc-main", "install.m"))
```

That one line:

1. downloads drpc from GitHub and unzips it to your temp folder
2. copies the `DiscordRPC` folder into your MATLAB user folder (`userpath`, usually `Documents\MATLAB`)
3. adds a small block to `startup.m` there, so drpc starts with MATLAB from now on
4. starts it

The first start takes a few seconds longer, because drpc compiles its bridge. After that your status shows up on Discord within a few seconds.

## Install by hand

1. Download the [latest release](https://github.com/akeanti/matlab-discord-rpc/releases/latest) and unzip it.
2. In MATLAB, `cd` into the unzipped folder and run `install`.

Or do what `install` does yourself: copy the `DiscordRPC` folder into your MATLAB user folder, add it to the path, then run `drpc setup` and `drpc start`.

## Check that it works

Type `drpc`:

```text
>> drpc

  Discord Rich Presence for MATLAB  v1.2.0

  Discord       Connected as you
  Showing       Editing pid_controller.m
                Function · Line 42 of 142
  Settings      config.json  (names on, idle after 10 min)

  pause   hide names   preview   restart   stop   docs
```

The **Discord** line should say `Connected as` and your name. The words at the bottom are links: click them instead of typing the commands.

> [!TIP]
> Connected, but nothing on your profile? In Discord, open **User Settings → Activity Privacy** and turn on **Share your detected activities with others**.

## What it shows

| When you're... | Discord shows |
|---|---|
| typing in the Editor | **Editing pid_controller.m** · Function · Line 42 of 142 · unsaved |
| running code | **Running sweep_bode.m**, timed from when the run started |
| stopped at a breakpoint | **Debugging kalman_step.m** · Paused at line 87 |
| running a Simulink model | **Simulating motor_model** · Simulink · 45% done |
| in a Simulink window | **Building motor_model** · Simulink · 48 blocks |
| in App Designer | **Designing scope_ui.mlapp** |
| looking at a figure | **Viewing Figure 2: Bode Plot** · 3 figures open |
| in the Command Window | **In the Command Window** · Folder: lab3 · 14 variables |
| gone for 10 minutes | **Away from keyboard** · Last on pid_controller.m |

Hover the small icon on Discord to see the folder and how many files are open. Close MATLAB and the status goes away.

Want file names hidden, or a project kept private? See [Privacy](./privacy). Everything else is in [Configuration](./configuration).

## Update

```matlab
drpc update
```

drpc asks GitHub for the newest release. If it's newer than yours, it links the release notes, then downloads and installs it. Your `config.json` is kept.

If the update changed the bridge, `drpc` will tell you to restart MATLAB. Until you do, the old bridge keeps working.

## Uninstall

```matlab
drpc uninstall
```

This clears your status, stops drpc and removes its block from `startup.m`. To remove the files too, restart MATLAB and delete the `DiscordRPC` folder in your MATLAB user folder.

## When drpc stays off on purpose

`startup.m` also runs in sessions where nobody is looking at MATLAB. drpc doesn't start itself in those:

- `matlab -batch` jobs and compiled apps
- parallel pool workers (`parpool`, `parfor`, `parfeval`)
- MATLAB Engine sessions started from Python, C++ or Java
- `-nodesktop` sessions

Run `drpc start` if you want it there anyway.
