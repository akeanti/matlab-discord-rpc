<script setup lang="ts">
import { withBase } from 'vitepress'
import ProfilePopout from './ProfilePopout.vue'

// Behind the hero: a MATLAB-style figure of a second-order step response,
// the plot every controls student has stared at for six hours. The step
// comes at t = 5 s, so the overshoot lands between the text and the card.
const W = 1200
const H = 600
const x0 = 40
const xs = (W - 2 * x0) / 10 // 10 s across
const yBase = 560
const ys = 250 // y = 1 is 250 px up
const tStep = 5
const zeta = 0.3
const wn = 3.2
const wd = wn * Math.sqrt(1 - zeta * zeta)
const pts: string[] = []
for (let i = 0; i <= 500; i++) {
  const t = (i / 500) * 10
  const u = t - tStep
  const y = u <= 0 ? 0 : 1 - Math.exp(-zeta * wn * u) * (Math.cos(wd * u) + (zeta / Math.sqrt(1 - zeta * zeta)) * Math.sin(wd * u))
  pts.push(`${(x0 + t * xs).toFixed(1)},${(yBase - y * ys).toFixed(1)}`)
}
const trace = 'M' + pts.join(' L')
const setpoint = yBase - ys
const pct = (v: number, of: number) => `${((v / of) * 100).toFixed(3)}%`
const ticks = Array.from({ length: 11 }, (_, i) => ({ x: x0 + i * xs, left: pct(x0 + i * xs, W), label: String(i) }))
const axisTop = pct(yBase, H)
const setTop = pct(setpoint, H)
const setRight = pct(x0, W)
const install = '#install'
</script>

<template>
  <section class="hero">
    <div class="plot" aria-hidden="true">
      <svg :viewBox="`0 0 ${W} ${H}`" preserveAspectRatio="none">
        <g class="grid">
          <line v-for="t in ticks" :key="'v' + t.x" :x1="t.x" :x2="t.x" y1="0" :y2="yBase" />
          <line v-for="k in 9" :key="'h' + k" :x1="x0" :x2="W - x0" :y1="yBase - k * 62.5" :y2="yBase - k * 62.5" />
        </g>
        <line class="axis" :x1="x0" :x2="W - x0" :y1="yBase" :y2="yBase" />
        <line class="setpoint" :x1="x0" :x2="W - x0" :y1="setpoint" :y2="setpoint" />
      </svg>
      <svg class="traces" :viewBox="`0 0 ${W} ${H}`" preserveAspectRatio="none">
        <path class="trace-glow" :d="trace" />
        <path class="trace" :d="trace" />
      </svg>
      <span class="label" :style="{ top: setTop, right: setRight }">r(t) = 1</span>
      <span v-for="t in ticks" :key="'t' + t.x" class="tick" :style="{ left: t.left, top: axisTop }">{{ t.label }}</span>
      <span class="unit" :style="{ top: axisTop, right: setRight }">t (s)</span>
    </div>

    <div class="inner">
      <div class="copy">
        <p class="prompt"><span>&gt;&gt;</span> drpc</p>
        <h1>Discord Rich Presence for <em>MATLAB</em></h1>
        <p class="lede">
          Discord shows when you're gaming or listening to Spotify. Six hours deep in MATLAB? Nothing.
          <strong>drpc</strong> fixes that. It runs inside MATLAB, so there's no Python and no extra app to keep open.
        </p>
        <div class="actions">
          <a class="btn brand" :href="install">Install in one line</a>
          <a class="btn alt" :href="withBase('/getting-started')">Read the guide</a>
          <a class="btn ghost" href="https://github.com/akeanti/matlab-discord-rpc" target="_blank" rel="noreferrer">
            <svg viewBox="0 0 16 16" aria-hidden="true">
              <path
                fill="currentColor"
                d="M8 0C3.58 0 0 3.58 0 8a8 8 0 0 0 5.47 7.59c.4.07.55-.17.55-.38v-1.33c-2.23.48-2.7-1.07-2.7-1.07-.36-.92-.89-1.17-.89-1.17-.73-.5.06-.49.06-.49.8.06 1.23.83 1.23.83.72 1.23 1.88.87 2.34.67.07-.52.28-.87.5-1.07-1.78-.2-3.65-.89-3.65-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82a7.6 7.6 0 0 1 4 0c1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48v2.2c0 .21.15.46.55.38A8 8 0 0 0 16 8c0-4.42-3.58-8-8-8Z"
              />
            </svg>
            GitHub
          </a>
        </div>
        <ul class="facts">
          <li>Windows 10 &amp; 11</li>
          <li>MATLAB R2021a+</li>
          <li>Simulink aware</li>
          <li>MIT</li>
        </ul>
      </div>
      <ProfilePopout class="visual" />
    </div>
  </section>
</template>

<style scoped>
.hero {
  position: relative;
  overflow: hidden;
  padding: calc(var(--vp-nav-height) + 56px) 24px 88px;
  border-bottom: 1px solid var(--vp-c-divider);
  background:
    radial-gradient(900px 420px at 78% 38%, var(--drpc-glow), transparent 70%),
    var(--vp-c-bg);
}
.plot {
  position: absolute;
  inset: 0;
  pointer-events: none;
  -webkit-mask-image: linear-gradient(to bottom, transparent 0%, #000 22%, #000 100%);
  mask-image: linear-gradient(to bottom, transparent 0%, #000 22%, #000 100%);
}
.plot svg {
  width: 100%;
  height: 100%;
}
.grid line {
  stroke: var(--drpc-grid);
  stroke-width: 1;
  vector-effect: non-scaling-stroke;
}
.axis {
  stroke: var(--drpc-grid-strong);
  stroke-width: 1;
  vector-effect: non-scaling-stroke;
}
.setpoint {
  stroke: var(--vp-c-text-3);
  stroke-opacity: 0.45;
  stroke-dasharray: 6 6;
  vector-effect: non-scaling-stroke;
}
.label,
.tick,
.unit {
  position: absolute;
  font-family: var(--vp-font-family-mono);
  font-size: 12px;
  color: var(--vp-c-text-3);
  opacity: 0.8;
}
.label {
  transform: translateY(calc(-100% - 6px));
}
.tick {
  transform: translate(-50%, 10px);
}
.unit {
  transform: translateY(30px);
}
.plot svg {
  position: absolute;
  inset: 0;
}
.traces {
  animation: draw 2.4s cubic-bezier(0.45, 0, 0.2, 1) 0.15s both;
}
.trace,
.trace-glow {
  fill: none;
  stroke: var(--drpc-orange);
  stroke-linecap: round;
  stroke-linejoin: round;
}
.trace {
  stroke-width: 2.5;
  opacity: 0.9;
  vector-effect: non-scaling-stroke;
}
.trace-glow {
  stroke-width: 12;
  opacity: 0.16;
  filter: blur(5px);
  vector-effect: non-scaling-stroke;
}
@keyframes draw {
  from {
    clip-path: inset(0 100% 0 0);
  }
  to {
    clip-path: inset(0 0 0 0);
  }
}

.inner {
  position: relative;
  max-width: 1152px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 56px;
  align-items: center;
}
.copy {
  min-width: 0;
  max-width: 620px;
}
.prompt {
  font-family: var(--vp-font-family-mono);
  font-size: 14px;
  color: var(--vp-c-text-2);
  margin: 0 0 18px;
  letter-spacing: 0.02em;
}
.prompt span {
  color: var(--vp-c-brand-1);
  margin-right: 4px;
}
h1 {
  font-family: var(--drpc-font-display);
  font-stretch: 122%;
  font-weight: 850;
  font-size: clamp(40px, 6.4vw, 72px);
  line-height: 0.98;
  letter-spacing: -0.035em;
  color: var(--vp-c-text-1);
  margin: 0;
  text-wrap: balance;
}
h1 em {
  font-style: normal;
  color: var(--drpc-orange);
}
.lede {
  margin: 24px 0 0;
  font-size: 18px;
  line-height: 1.65;
  color: var(--vp-c-text-2);
  max-width: 30em;
}
.lede strong {
  color: var(--vp-c-text-1);
  font-weight: 600;
}
.actions {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-top: 32px;
}
.btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 44px;
  padding: 0 20px;
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
  background: var(--vp-c-bg);
}
.btn.alt:hover {
  border-color: var(--vp-c-brand-1);
  color: var(--vp-c-brand-1);
}
.btn.ghost {
  color: var(--vp-c-text-2);
}
.btn.ghost:hover {
  color: var(--vp-c-text-1);
}
.btn svg {
  width: 17px;
  height: 17px;
}
.facts {
  list-style: none;
  padding: 0;
  margin: 36px 0 0;
  display: flex;
  flex-wrap: wrap;
  gap: 8px 22px;
  font-family: var(--vp-font-family-mono);
  font-size: 12.5px;
  color: var(--vp-c-text-3);
}
.facts li {
  display: flex;
  align-items: center;
  gap: 8px;
}
.facts li::before {
  content: '';
  width: 5px;
  height: 5px;
  background: var(--drpc-orange);
  opacity: 0.75;
}

@media (max-width: 960px) {
  .inner {
    grid-template-columns: minmax(0, 1fr);
    gap: 48px;
  }
  .visual {
    justify-self: start;
  }
}
@media (max-width: 640px) {
  .hero {
    padding: calc(var(--vp-nav-height) + 32px) 16px 64px;
  }
  .lede {
    font-size: 16.5px;
  }
  .tick,
  .unit,
  .label,
  .traces,
  .setpoint {
    display: none;
  }
}
</style>
