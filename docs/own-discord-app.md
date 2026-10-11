# Using your own Discord app

drpc works out of the box with a shared Discord application, which is why your profile says **Playing MATLAB**. Make your own if you want a different name there or your own icons.

1. Go to the [Discord Developer Portal](https://discord.com/developers/applications) and click **New Application**.
2. The name you give it is what people see after "Playing". Pick something like `MATLAB`, `Simulink` or `Signals & Systems`.
3. Copy the **Application ID** from General Information.
4. Put it in `config.json`, in quotes:
   ```json
   "client_id": "123456789012345678"
   ```
5. Save. drpc reconnects with the new app within a few seconds.

> [!IMPORTANT]
> The application id is public by design. drpc never needs a client secret or a bot token, so don't put one anywhere.

## Icons

You have two options.

**Image URLs.** Point the `images` entries at any https PNG. The easiest place to host them is your own app: **Emojis** in the Developer Portal, upload, then use

```
https://cdn.discordapp.com/emojis/EMOJI_ID.png?size=512&quality=lossless
```

**Art assets.** Upload images under **Rich Presence > Art Assets** and use the asset names as the values:

```json
"images": { "matlab": "logo", "editing": "editing" }
```

New art assets can take a few minutes to show up.

The status icons in [`assets/icons`](https://github.com/akeanti/matlab-discord-rpc/tree/main/assets/icons) are free to use for either.
