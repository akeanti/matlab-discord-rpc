# Privacy

Your profile shows what drpc sends, and nothing else leaves MATLAB. This page covers what that is and how to hide parts of it.

## What gets sent, and where

drpc talks to one thing: the Discord app on your own PC, over its local named pipe (`\\.\pipe\discord-ipc-0`). Discord then shows it to people who can see your profile.

The only text it sends is what appears on your profile:

- the line about what you're doing, like **Editing pid_controller.m**
- the line under it, like **Function · Line 42 of 142**
- the hover text on the small icon (folder name, number of open files)
- your MATLAB release, like **MATLAB R2024a**, as hover text on the big icon
- any buttons you added yourself

It never sends your code, file contents, full paths, variable names or values. `drpc preview` prints the exact payload, so you can check.

The only time drpc goes on the internet itself is `drpc update`, which asks GitHub for the newest release and downloads it.

## Hide file names

```matlab
drpc names off
```

Discord now says "Editing a function", "Simulating a model", "Looking at plots" and so on. This covers file, model, app and figure names, and it sticks until you run `drpc names on`.

## Hide one project

Add any part of its path to `hidden_folders` in `config.json` (`drpc config` opens it):

```json
"hidden_folders": ["Internship", "Exam"]
```

Whenever the current folder or the file you're editing has one of these in its path, names and the folder are hidden. Matching ignores case and works on any part of the path, so `"Exam"` also matches `Exams` and `Example`.

## Hide the folder name

The folder shows in the Command Window line and the hover text. Turn it off with:

```json
"show_folder": false
```

## Hide everything for a while

```matlab
drpc pause
```

Your status disappears until `drpc resume` or the next MATLAB start. To turn drpc off for good, run `drpc uninstall`.

## If config.json has a typo

A broken `config.json` never turns names back on:

- While drpc is running, a save with an error keeps your previous settings. drpc prints what's wrong and gives you a link to open the file.
- If MATLAB starts with a broken file, drpc hides names until you fix it.

## Tokens and passwords

drpc never needs a Discord token, a client secret or a password. The application id in `config.json` is public by design. If something asks you for a token, it isn't drpc.

To report a security problem, use [private vulnerability reporting](https://github.com/akeanti/matlab-discord-rpc/security/advisories/new) instead of a public issue.
