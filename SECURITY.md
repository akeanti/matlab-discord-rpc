# Security

drpc only talks to the Discord desktop app on your own PC, over its local named pipe. It sends nothing anywhere else. The only network request it can make is `drpc update`, which downloads this repository from GitHub when you run it.

The bridge DLL is compiled on your machine from `DiscordRPC/DrpcBridge.cs`. No prebuilt binaries are shipped.

drpc never needs a Discord token, client secret or password. If anything asks you for one, it isn't this project.

To report a vulnerability, use [private vulnerability reporting](https://github.com/akeanti/matlab-discord-rpc/security/advisories/new) instead of a public issue.
