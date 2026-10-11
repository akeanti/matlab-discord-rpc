# FAQ

## Does it work on macOS or Linux?

Not yet. On those systems Discord listens on a Unix socket instead of a named pipe, and the bridge is built on .NET Framework, which is Windows only. Supporting them is doable, and [pull requests are welcome](https://github.com/akeanti/matlab-discord-rpc/blob/main/CONTRIBUTING.md).

## Does it send my code anywhere?

No. It only talks to the Discord app on your own PC, and the only text it sends is what you see on your profile. See [Privacy](./privacy).

## Can I keep a project private?

Add the folder name to `hidden_folders`, or run `drpc names off`. To hide everything for a while, run `drpc pause`. Details are in [Privacy](./privacy).

## Does it work with MATLAB Online?

No. Rich Presence needs the Discord desktop app on the same machine as MATLAB.

## Which MATLAB releases does it work on?

It's tested on R2024a, and anything from R2021a up should work. On R2025a and newer, telling the Editor apart from the Command Window relies on the old desktop, so that one detail may be off. [Let me know](https://github.com/akeanti/matlab-discord-rpc/issues) how it goes.

## Will it slow MATLAB down?

It shouldn't. Every 2 seconds drpc takes a quick snapshot (the Editor, the window in front, Simulink if it's already loaded) and hands it to a background thread. All the waiting on Discord happens on that thread, never on MATLAB's.

## Why does my profile say "Playing MATLAB"?

drpc uses a shared Discord application named MATLAB. Make your own app if you want it to say "Playing Simulink" or "Playing Signals & Systems": see [Your own Discord app](./own-discord-app).

## Why does it say "Running" when I'm not running anything?

Something in MATLAB is using a lot of CPU, which heavy 3D figures can do. Raise `busy_cpu_percent` in `config.json`, or set `detect_running` to `false`. See [Troubleshooting](./troubleshooting#running-shows-when-i-m-not-running-anything).

## Does it start in my parfor workers or batch jobs?

No. drpc only starts itself when there's a MATLAB desktop. `-batch` jobs, parallel workers, MATLAB Engine sessions and `-nodesktop` sessions are left alone.

## Is the shipped code safe to run?

The repo contains no DLLs or EXEs. The C# bridge is compiled on your PC from [`DrpcBridge.cs`](https://github.com/akeanti/matlab-discord-rpc/blob/main/DiscordRPC/DrpcBridge.cs) by the compiler that ships with Windows, so what runs is what you can read. The whole project is two source files.

## Can I use the icons in my own project?

Yes. The status icons in [`assets/icons`](https://github.com/akeanti/matlab-discord-rpc/tree/main/assets/icons) are free to use.
