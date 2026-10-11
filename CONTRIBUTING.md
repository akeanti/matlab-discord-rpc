# Contributing

Bug reports, ideas and pull requests are all welcome. If you use MATLAB in a way drpc doesn't show yet (Stateflow, MATLAB Online, a toolbox with its own window), an issue describing what you'd want Discord to say is a great start.

## Layout

```
DiscordRPC/drpc.m          MATLAB side: snapshot, activity, commands
DiscordRPC/DrpcBridge.cs   Discord side: pipe, rate limit, watchdog
install.m                  copies DiscordRPC into the user folder
tests/DrpcTest.m           MATLAB unit tests
tests/                     bridge tests against a fake Discord
docs/                      the docs, which are also the website
```

## Working on drpc.m

Edit the copy in your MATLAB user folder (`fullfile(userpath, 'DiscordRPC')`) and run `drpc restart`. `drpc preview` shows the payload and what drpc detected.

Run the unit tests from the repo root:

```matlab
addpath DiscordRPC
runtests tests
```

They call the local functions in `drpc.m` through its hidden `drpc __test__` hook, so they need neither Windows nor Discord. CI runs them on R2021a and on the latest release.

A few rules that keep it safe to run in everyone's MATLAB:

- `tick` must never throw. An error in a `TimerFcn` stops the timer.
- Never load anything heavy from a tick. Simulink is only queried if it is already loaded.
- Keep it working on R2021a: no newer-only functions without a fallback.
- No new dependencies. No Python, no toolboxes.

## Working on DrpcBridge.cs

The bridge has to compile with the `csc.exe` from .NET Framework 4, so it is **C# 5 only**: no `$""`, `?.`, `=>` members or `out var`. CI checks this with `mcs -langversion:5` and with the real `csc.exe` on Windows.

.NET can't unload an assembly, so restart MATLAB after changing the bridge.

Run the tests on Windows (needs Python 3):

```powershell
powershell -ExecutionPolicy Bypass -File tests\run.ps1
```

or on Linux and macOS (needs `mono` and `python3`):

```bash
bash tests/run.sh
```

They build the bridge with `-define:DRPC_TCP_TEST`, which swaps the named pipe for TCP, and run it against `tests/fake_discord.py`: connecting, rate limits, the watchdog, rejected payloads, pause, Discord restarting, bad app ids.

## Working on the docs

The pages in `docs/` are the website. To preview it (needs Node 20+):

```bash
cd docs
npm install
npm run dev
```

The home page is `docs/.vitepress/theme/components/HomePage.vue`. Pushing to `main` deploys the site.

## Pull requests

- One change per PR, with a line in `CHANGELOG.md`
- Say which MATLAB release you tried it on
- Screenshots of what Discord shows are the best review aid there is
