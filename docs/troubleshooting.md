# Troubleshooting

Start with `drpc`. The **Discord** line says what the bridge is doing, and `drpc preview` prints the exact payload plus live diagnostics.

### "Discord is not running"

drpc talks to the **Discord desktop app**. Discord in a browser can't receive Rich Presence. If the desktop app is open and you still see this, check that MATLAB and Discord run at the same privilege level: if one is started as administrator and the other isn't, Windows blocks the pipe between them.

### Connected, but nothing on my profile

In Discord: **User Settings > Activity Privacy > Share your detected activities with others** must be on.

### "config.json has an error"

The file isn't valid JSON, often because of a trailing comma or a missing quote. drpc keeps your previous settings and prints where the problem is. Fix it, save, and drpc confirms the new settings are on.

### "Discord said: ..."

Discord rejected the last update. That is usually a broken image URL or button in `config.json`. Fix it and save; the next update clears the message.

### "Bridge x.y.z is loaded; restart MATLAB"

.NET assemblies can't be unloaded, so after `drpc update` changes the bridge, the old one stays in memory until MATLAB restarts. Everything keeps working in the meantime.

### "The C# compiler that ships with Windows was not found"

drpc compiles its bridge with .NET Framework 4, which is part of Windows 10 and 11. If it was removed, turn it back on under **Windows Features > .NET Framework 4.8 Advanced Services**.

### It doesn't start with MATLAB

drpc only starts itself when there's a MATLAB desktop, so `-batch`, `-nodesktop`, parallel workers and MATLAB Engine sessions are skipped on purpose. Run `drpc start` there if you want it.

Otherwise, run `which -all startup`. MATLAB only runs the first `startup.m` on the path; drpc adds its block to the one in your MATLAB user folder (`userpath`). If another one comes first, copy the block between the `MATLAB Discord RPC` markers into it, or run `drpc setup` after fixing the path.

### "Running" shows when I'm not running anything

Something in MATLAB is using a lot of CPU (heavy 3D figures can). Raise `busy_cpu_percent`, or set `detect_running` to `false`. The watchdog for frozen MATLAB still works either way.

### Editing vs Command Window looks wrong

drpc tells the two apart through the Java desktop. MATLAB R2025a and later use a new desktop where that isn't available, so drpc falls back to "Editing" whenever a file is open. Tested on R2024a; [reports from newer releases](https://github.com/akeanti/matlab-discord-rpc/issues) are welcome.

### Icons are blank

The image keys must match art asset names in your own app, or be full `https://` URLs. Discord caches images, so a replaced image can take a while to update.

### Still stuck

[Open an issue](https://github.com/akeanti/matlab-discord-rpc/issues/new/choose) with the output of `drpc preview`.
