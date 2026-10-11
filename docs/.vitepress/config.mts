import { defineConfig } from 'vitepress'

const repo = 'https://github.com/akeanti/matlab-discord-rpc'
const site = 'https://akeanti.xyz/matlab-discord-rpc/'
const title = 'drpc'
const description =
  "Discord Rich Presence for MATLAB. Shows what you're editing, running, debugging or simulating. Runs inside MATLAB, no Python needed."
const ogImage = 'https://raw.githubusercontent.com/akeanti/matlab-discord-rpc/main/assets/social-preview.png'

export default defineConfig({
  title,
  titleTemplate: ':title · drpc',
  description,
  lang: 'en-US',
  base: '/matlab-discord-rpc/',
  cleanUrls: true,
  lastUpdated: true,
  appearance: 'dark',
  srcExclude: ['README.md'],
  sitemap: { hostname: site },

  head: [
    ['link', { rel: 'icon', type: 'image/png', href: '/matlab-discord-rpc/favicon.png' }],
    ['link', { rel: 'apple-touch-icon', href: '/matlab-discord-rpc/apple-touch-icon.png' }],
    ['meta', { name: 'theme-color', content: '#0b0e18' }],
    ['link', { rel: 'preconnect', href: 'https://fonts.googleapis.com' }],
    ['link', { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' }],
    [
      'link',
      {
        rel: 'stylesheet',
        href: 'https://fonts.googleapis.com/css2?family=Archivo:wdth,wght@100..125,500..900&family=IBM+Plex+Mono:wght@400;500;600&family=IBM+Plex+Sans:ital,wght@0,400;0,500;0,600;0,700;1,400&display=swap'
      }
    ],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:site_name', content: 'drpc' }],
    ['meta', { property: 'og:title', content: 'drpc · Discord Rich Presence for MATLAB' }],
    ['meta', { property: 'og:description', content: description }],
    ['meta', { property: 'og:image', content: ogImage }],
    ['meta', { property: 'og:url', content: site }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { name: 'twitter:image', content: ogImage }]
  ],

  markdown: {
    theme: { light: 'github-light', dark: 'github-dark-dimmed' },
    config(md) {
      // ```mermaid fences render as diagrams, like they do on GitHub
      const fence = md.renderer.rules.fence!
      md.renderer.rules.fence = (tokens, idx, options, env, self) => {
        const token = tokens[idx]
        if (token.info.trim() === 'mermaid') {
          return `<MermaidDiagram code="${encodeURIComponent(token.content)}" />`
        }
        return fence(tokens, idx, options, env, self)
      }
    }
  },

  vite: {
    // the pages use the icons in /assets at the repo root
    server: { fs: { allow: ['..'] } },
    // mermaid is big, but only the How it works page loads it
    build: { chunkSizeWarningLimit: 3000 }
  },

  themeConfig: {
    logo: { src: '/logo.png', alt: '' },
    siteTitle: 'drpc',

    nav: [
      { text: 'Guide', link: '/getting-started', activeMatch: '^/(getting-started|commands|configuration|own-discord-app|privacy)' },
      { text: 'How it works', link: '/how-it-works' },
      { text: 'Help', link: '/troubleshooting', activeMatch: '^/(troubleshooting|faq)' },
      {
        text: 'v1.1.0',
        items: [
          { text: 'Changelog', link: `${repo}/blob/main/CHANGELOG.md` },
          { text: 'Releases', link: `${repo}/releases` },
          { text: 'Contributing', link: `${repo}/blob/main/CONTRIBUTING.md` }
        ]
      }
    ],

    sidebar: [
      {
        text: 'Start here',
        items: [
          { text: 'Getting started', link: '/getting-started' },
          { text: 'Commands', link: '/commands' },
          { text: 'Configuration', link: '/configuration' }
        ]
      },
      {
        text: 'Make it yours',
        items: [
          { text: 'Privacy', link: '/privacy' },
          { text: 'Your own Discord app', link: '/own-discord-app' }
        ]
      },
      {
        text: 'Under the hood',
        items: [{ text: 'How it works', link: '/how-it-works' }]
      },
      {
        text: 'Help',
        items: [
          { text: 'Troubleshooting', link: '/troubleshooting' },
          { text: 'FAQ', link: '/faq' }
        ]
      }
    ],

    socialLinks: [{ icon: 'github', link: repo }],

    search: { provider: 'local' },

    outline: { level: [2, 3], label: 'On this page' },

    editLink: {
      pattern: `${repo}/edit/main/docs/:path`,
      text: 'Edit this page on GitHub'
    },

    footer: {
      message:
        'MIT licensed. Not affiliated with MathWorks or Discord. MATLAB and Simulink are registered trademarks of The MathWorks, Inc.',
      copyright: `Made by <a href="https://github.com/akeanti">akeanti</a>`
    },

    docFooter: { prev: 'Previous', next: 'Next' },
    externalLinkIcon: true
  }
})
