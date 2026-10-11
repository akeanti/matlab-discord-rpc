# drpc docs

These pages are the website at **https://akeanti.xyz/matlab-discord-rpc/**. They also read fine right here on GitHub:

- [Getting started](getting-started.md)
- [Commands](commands.md)
- [Configuration](configuration.md)
- [Privacy](privacy.md)
- [Your own Discord app](own-discord-app.md)
- [How it works](how-it-works.md)
- [Troubleshooting](troubleshooting.md)
- [FAQ](faq.md)

## Working on the site

The site is built with [VitePress](https://vitepress.dev). You need Node 20 or newer.

```bash
cd docs
npm install
npm run dev
```

The home page lives in `.vitepress/theme/components/HomePage.vue`; everything else is the Markdown in this folder. Pushing to `main` deploys the site through `.github/workflows/docs.yml`.
