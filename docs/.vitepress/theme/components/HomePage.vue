<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { withBase } from 'vitepress'
import HomeHero from './HomeHero.vue'
import DiscordCard from './DiscordCard.vue'
import CopyButton from './CopyButton.vue'
import Pipeline from './Pipeline.vue'
import CommandWindow from './CommandWindow.vue'
import { states } from '../states'

const oneLiner =
  'unzip("https://github.com/akeanti/matlab-discord-rpc/archive/refs/heads/main.zip", tempdir); run(fullfile(tempdir, "matlab-discord-rpc-main", "install.m"))'

const sec = ref(0)
let timer: ReturnType<typeof setInterval> | undefined
onMounted(() => {
  const t0 = Date.now()
  timer = setInterval(() => (sec.value = Math.floor((Date.now() - t0) / 1000)), 1000)
})
onBeforeUnmount(() => clearInterval(timer))

const why = [
  {
    spec: '0 dependencies',
    title: 'Runs inside MATLAB',
    text: "No Python, no Node, no tray app. If MATLAB is open, drpc is running. Close MATLAB and your status goes away with it."
  },
  {
    spec: '4 s watchdog',
    title: 'Knows when code is running',
    text: "A long loop keeps MATLAB from reporting anything. A watchdog on a background thread notices the silence and switches you to Running, timed from when the run started."
  },
  {
    spec: 'background thread',
    title: 'MATLAB never waits on Discord',
    text: "All Discord traffic happens off MATLAB's thread. Discord closed, restarting or slow? MATLAB doesn't notice, and drpc reconnects when Discord is back."
  },
  {
    spec: '0 binaries in the repo',
    title: 'Built from source on your PC',
    text: 'The bridge that talks to Discord is compiled from DrpcBridge.cs by the C# compiler that ships with Windows. What runs is what you can read.'
  },
  {
    spec: 'drpc names off',
    title: 'Private when you want it',
    text: 'Hide file names, hide whole folders like Internship or Exam, or pause for the session. Only what you see on your profile ever leaves MATLAB.'
  },
  {
    spec: 'applies in 2 s',
    title: 'Settings apply on save',
    text: 'Edit config.json and the change is live on the next tick. Make a typo and drpc tells you, while your previous settings stay on.'
  }
]
</script>

<template>
  <div class="home">
    <HomeHero />

    <section id="install" class="band install">
      <div class="wrap">
        <div class="head">
          <h2>Install in one line</h2>
          <p>
            Paste this into the MATLAB Command Window. Your status shows up on Discord a few seconds later, and from
            then on drpc starts with MATLAB by itself.
          </p>
        </div>
        <div class="cmd">
          <div class="cmd-bar">
            <span class="cmd-title">Command Window</span>
            <CopyButton :text="oneLiner" label="Copy command" />
          </div>
          <pre class="cmd-line"><code><span class="p">&gt;&gt;</span> {{ oneLiner }}</code></pre>
        </div>
        <ul class="needs">
          <li><strong>Windows 10 or 11</strong><span>uses the C# compiler Windows already has</span></li>
          <li><strong>Discord desktop app</strong><span>the browser version can't show Rich Presence</span></li>
          <li><strong>MATLAB R2021a or newer</strong><span>tested on R2024a, Simulink optional</span></li>
        </ul>
        <p class="more">
          Rather download it yourself? See <a :href="withBase('/getting-started#install-by-hand')">installing by hand</a>.
        </p>
      </div>
    </section>

    <section class="band shows">
      <div class="wrap">
        <div class="head">
          <h2>What your friends see</h2>
          <p>
            Every 2 seconds drpc looks at the Editor, the window in front, Simulink and the debugger, and picks the
            line that matches what you're doing. Hover a small icon to see its tooltip.
          </p>
        </div>
        <div class="grid">
          <div v-for="s in states" :key="s.id" class="cell">
            <div class="when"><span>When you're</span> {{ s.when }}</div>
            <DiscordCard :s="s" :elapsed="sec" />
          </div>
        </div>
      </div>
    </section>

    <section class="band why">
      <div class="wrap">
        <div class="head">
          <h2>Built to stay out of your way</h2>
          <p>drpc is one MATLAB file and one small C# file. Here is what that buys you.</p>
        </div>
        <div class="points">
          <article v-for="w in why" :key="w.title" class="point">
            <code class="spec">{{ w.spec }}</code>
            <h3>{{ w.title }}</h3>
            <p>{{ w.text }}</p>
          </article>
        </div>
      </div>
    </section>

    <section class="band how">
      <div class="wrap">
        <div class="head">
          <h2>From the Editor to your profile</h2>
          <p>
            A MATLAB timer takes a snapshot, a background thread does the talking, and Discord's own named pipe carries
            it the last few centimetres.
          </p>
        </div>
        <Pipeline />
        <p class="more">
          The watchdog, the rate limit and the exact checks are in <a :href="withBase('/how-it-works')">How it works</a>.
        </p>
      </div>
    </section>

    <section class="band commands">
      <div class="wrap split">
        <div class="head">
          <h2>Driven from the Command Window</h2>
          <p>
            Type <code>drpc</code> for a status report with clickable actions. Everything else is one word away.
          </p>
          <dl class="cmds">
            <div><dt>drpc pause</dt><dd>hide your status for this session</dd></div>
            <div><dt>drpc names off</dt><dd>"Editing a function" instead of the file name</dd></div>
            <div><dt>drpc config</dt><dd>open the settings, applied on save</dd></div>
            <div><dt>drpc preview</dt><dd>the exact payload plus diagnostics</dd></div>
            <div><dt>drpc update</dt><dd>install the newest release</dd></div>
          </dl>
          <p class="more"><a :href="withBase('/commands')">All commands</a></p>
        </div>
        <CommandWindow />
      </div>
    </section>

    <section class="band end">
      <div class="wrap">
        <h2>Give those six hours something to show for it.</h2>
        <div class="end-actions">
          <a class="btn brand" href="#install">Install drpc</a>
          <a class="btn alt" :href="withBase('/getting-started')">Getting started</a>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.home {
  --gutter: 24px;
}
.band {
  padding: 96px var(--gutter);
  border-bottom: 1px solid var(--vp-c-divider);
}
.wrap {
  max-width: 1152px;
  margin: 0 auto;
}
.head {
  max-width: 640px;
  min-width: 0;
}
h2 {
  font-family: var(--drpc-font-display);
  font-stretch: 116%;
  font-weight: 800;
  font-size: clamp(28px, 3.6vw, 40px);
  line-height: 1.08;
  letter-spacing: -0.03em;
  color: var(--vp-c-text-1);
  margin: 0;
  text-wrap: balance;
}
.head p {
  margin: 16px 0 0;
  font-size: 17px;
  line-height: 1.7;
  color: var(--vp-c-text-2);
}
.head code,
.more code {
  font-family: var(--vp-font-family-mono);
  font-size: 0.88em;
  padding: 2px 6px;
  border-radius: 4px;
  background: var(--vp-code-bg);
  color: var(--vp-code-color);
}
.more {
  margin: 28px 0 0;
  color: var(--vp-c-text-2);
  font-size: 15px;
}
.more a {
  color: var(--vp-c-brand-1);
  font-weight: 500;
  text-underline-offset: 3px;
}

/* install */
.install {
  background: var(--vp-c-bg-alt);
}
.cmd {
  margin-top: 36px;
  border: 1px solid var(--drpc-panel-edge);
  border-radius: 6px;
  background: var(--drpc-cmd-bg);
  overflow: hidden;
}
.cmd-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 8px 8px 8px 16px;
  border-bottom: 1px solid var(--drpc-panel-edge);
  background: var(--vp-c-bg-soft);
}
.cmd-title {
  font-family: var(--vp-font-family-mono);
  font-size: 12px;
  color: var(--vp-c-text-3);
  letter-spacing: 0.04em;
}
.cmd-line {
  margin: 0;
  padding: 20px 20px 22px;
  overflow-x: auto;
  font-family: var(--vp-font-family-mono);
  font-size: 14px;
  line-height: 1.7;
  color: var(--drpc-cmd-text);
  white-space: pre-wrap;
  overflow-wrap: anywhere;
  padding-left: 46px;
  text-indent: -26px;
}
.cmd-line .p {
  color: var(--drpc-cmd-prompt);
  user-select: none;
}
.needs {
  list-style: none;
  margin: 28px 0 0;
  padding: 0;
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px 32px;
}
.needs li {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding-top: 14px;
  border-top: 1px solid var(--vp-c-divider);
}
.needs strong {
  color: var(--vp-c-text-1);
  font-weight: 600;
}
.needs span {
  color: var(--vp-c-text-3);
  font-size: 14px;
}

/* states */
.grid {
  margin-top: 44px;
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 28px 20px;
}
.cell {
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-width: 0;
}
.when {
  font-family: var(--vp-font-family-mono);
  font-size: 12.5px;
  color: var(--vp-c-text-1);
}
.when span {
  color: var(--vp-c-text-3);
}
.cell :deep(.dc-card) {
  box-shadow: 0 0 0 1px var(--vp-c-divider);
  transition: transform 0.25s ease, box-shadow 0.25s ease;
}
.cell:hover :deep(.dc-card) {
  transform: translateY(-2px);
  box-shadow: 0 0 0 1px var(--vp-c-border), 0 14px 30px -18px rgba(0, 0, 0, 0.6);
}

/* why */
.why {
  background: var(--vp-c-bg-alt);
}
.points {
  margin-top: 48px;
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 44px 40px;
}
.point {
  min-width: 0;
  padding-top: 18px;
  border-top: 1px solid var(--vp-c-border);
}
.spec {
  font-family: var(--vp-font-family-mono);
  font-size: 12px;
  color: var(--vp-c-brand-1);
  letter-spacing: 0.02em;
}
.point h3 {
  margin: 10px 0 0;
  font-family: var(--drpc-font-display);
  font-stretch: 108%;
  font-weight: 700;
  font-size: 19px;
  letter-spacing: -0.01em;
  color: var(--vp-c-text-1);
}
.point p {
  margin: 10px 0 0;
  color: var(--vp-c-text-2);
  line-height: 1.7;
  font-size: 15px;
}

/* commands */
.split {
  display: grid;
  grid-template-columns: minmax(0, 0.9fr) minmax(0, 1.1fr);
  gap: 56px;
  align-items: center;
}
.cmds {
  margin: 28px 0 0;
  display: grid;
  gap: 0;
}
.cmds div {
  display: grid;
  grid-template-columns: 9.5em minmax(0, 1fr);
  gap: 16px;
  padding: 10px 0;
  border-top: 1px solid var(--vp-c-divider);
}
.cmds dt {
  font-family: var(--vp-font-family-mono);
  font-size: 13.5px;
  color: var(--vp-c-brand-1);
}
.cmds dd {
  margin: 0;
  color: var(--vp-c-text-2);
  font-size: 14.5px;
}

/* end */
.end {
  border-bottom: 0;
  padding-block: 110px;
  background:
    radial-gradient(640px 260px at 50% 78%, var(--drpc-glow), transparent 70%),
    var(--vp-c-bg);
}
.end .wrap {
  text-align: center;
}
.end h2 {
  font-size: clamp(30px, 4.6vw, 52px);
  max-width: 16em;
  margin: 0 auto;
}
.end-actions {
  margin-top: 32px;
  display: flex;
  justify-content: center;
  flex-wrap: wrap;
  gap: 12px;
}
.btn {
  display: inline-flex;
  align-items: center;
  height: 46px;
  padding: 0 22px;
  border-radius: 6px;
  font-weight: 600;
  font-size: 15px;
  text-decoration: none;
  transition: background-color 0.2s, border-color 0.2s, color 0.2s, transform 0.2s;
}
.btn:focus-visible {
  outline: 2px solid var(--vp-c-brand-1);
  outline-offset: 3px;
}
.btn.brand {
  background: var(--vp-button-brand-bg);
  color: var(--vp-button-brand-text);
}
.btn.brand:hover {
  background: var(--vp-button-brand-hover-bg);
  transform: translateY(-1px);
}
.btn.alt {
  border: 1px solid var(--vp-c-border);
  color: var(--vp-c-text-1);
}
.btn.alt:hover {
  border-color: var(--vp-c-brand-1);
  color: var(--vp-c-brand-1);
}

@media (max-width: 960px) {
  .grid,
  .points {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .split {
    grid-template-columns: minmax(0, 1fr);
  }
}
@media (max-width: 640px) {
  .home {
    --gutter: 16px;
  }
  .band {
    padding-block: 64px;
  }
  .grid,
  .points,
  .needs {
    grid-template-columns: minmax(0, 1fr);
  }
  .cmds div {
    grid-template-columns: minmax(0, 1fr);
    gap: 2px;
  }
}
</style>
