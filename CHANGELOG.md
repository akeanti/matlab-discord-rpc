# Changelog

## 1.2.0

- `hidden_folders` now also hides the Simulink model and the App Designer app you're working on when its file is in a hidden folder. Before, only the current folder and the Editor file were checked, so a model opened from `Exam\` still showed its name if the current folder was somewhere else
- Functions and classes that start with a `%{ ... %}` block comment show as "Function" and "Class" instead of "Script"
- A button URL over 512 characters is skipped. Before, Discord rejected the whole status and nothing showed
- Long names are never cut in the middle of an emoji
- `drpc update` still finds the newest release when GitHub's API limit is used up, which happens fast on campus networks. Before, it installed the unreleased code from `main` instead. It also links the release notes

## 1.1.0

- New website with the docs: https://akeanti.xyz/matlab-discord-rpc/ (`drpc docs` opens it)
- drpc no longer starts itself in `-batch` jobs, parallel pool workers, MATLAB Engine sessions or `-nodesktop`. Before, every `parfor` worker could put its own status on Discord
- Saving `config.json` with a JSON error keeps your previous settings and tells you what's wrong. Before, drpc silently fell back to the defaults, which turned hidden names back on. If MATLAB starts with a broken file, names stay hidden until it's fixed
- `drpc names` changes only `show_names` in `config.json` and leaves the rest of the file as you wrote it
- New `config.json` files leave out `client_id` and `images`, so those keep following the defaults
- `drpc update` installs the newest release, and says so when you're already on it
- `drpc restart` no longer flashes the previous run's "Running" status on Discord
- `drpc stop` no longer waits for a connection attempt to finish
- `drpc config` creates `config.json` if it's missing, and two saves within the same second are both picked up
- Bridges built from older sources are removed from `bin/`
- MATLAB unit tests, run in CI on R2021a and the latest release
- `tests/run.ps1` runs the bridge tests on Windows with the built-in `csc.exe`, no WSL or mono needed

## 1.0.0

First public release.

- Shows editing, running, debugging, Simulink, App Designer, figures, Command Window and away states
- Watchdog keeps "Running" on Discord while MATLAB is too busy to report
- Runs inside MATLAB: no Python, no installer, no background app
- C# bridge compiled from source on first run with the compiler that ships with Windows
- `drpc` commands for status, pause, names, config, preview, update and uninstall
- One-line install from the Command Window
