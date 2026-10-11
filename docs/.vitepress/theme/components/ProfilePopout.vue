<script setup lang="ts">
// A Discord profile popout that cycles through what drpc shows.
import { onBeforeUnmount, onMounted, ref } from 'vue'
import DiscordCard from './DiscordCard.vue'
import { states } from '../states'

const cycle = ['edit', 'run', 'debug', 'sim', 'plot', 'idle'].map((id) => states.find((s) => s.id === id)!)
const idx = ref(0)
const sec = ref(0)
const hovering = ref(false)

let shownFor = 0
let pinnedUntil = 0
let timer: ReturnType<typeof setInterval> | undefined

onMounted(() => {
  const t0 = Date.now()
  timer = setInterval(() => {
    sec.value = Math.floor((Date.now() - t0) / 1000)
    if (hovering.value || Date.now() < pinnedUntil) return
    if (++shownFor >= 4) {
      shownFor = 0
      idx.value = (idx.value + 1) % cycle.length
    }
  }, 1000)
})
onBeforeUnmount(() => clearInterval(timer))

function pick(i: number) {
  idx.value = i
  shownFor = 0
  pinnedUntil = Date.now() + 12000
}
</script>

<template>
  <figure class="popout-wrap" aria-label="Example Discord profile showing drpc">
    <div class="popout" @mouseenter="hovering = true" @mouseleave="hovering = false">
      <div class="banner" aria-hidden="true">
        <svg viewBox="0 0 340 96" preserveAspectRatio="none">
          <path d="M0 70 C 40 70, 50 20, 90 22 S 140 80, 180 62 S 250 30, 340 44" />
          <path d="M0 84 C 50 84, 70 50, 110 52 S 170 92, 220 78 S 290 60, 340 66" />
        </svg>
      </div>
      <div class="avatar" aria-hidden="true">
        <svg viewBox="0 0 80 80">
          <circle cx="40" cy="40" r="40" fill="var(--dc-blurple)" />
          <path
            d="M20 42 C 24 31, 27 26, 31 26 C 37 26, 41 56, 49 56 C 53 56, 56 50, 60 40"
            fill="none"
            stroke="#fff"
            stroke-width="6"
            stroke-linecap="round"
          />
        </svg>
        <span class="status" title="Online" />
      </div>
      <div class="who">
        <div class="name">Ada</div>
        <div class="handle">ada.m</div>
      </div>
      <div class="activity">
        <DiscordCard
          v-for="(s, i) in cycle"
          :key="s.id"
          :s="s"
          :elapsed="sec"
          :class="{ on: i === idx }"
          :aria-hidden="i !== idx"
        />
      </div>
    </div>
    <div class="chips" role="group" aria-label="Pick what Ada is doing">
      <button
        v-for="(s, i) in cycle"
        :key="s.id"
        type="button"
        :aria-pressed="i === idx"
        @click="pick(i)"
      >
        {{ s.short }}
      </button>
    </div>
  </figure>
</template>

<style scoped>
.popout-wrap {
  margin: 0;
  width: 100%;
  max-width: 360px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.popout {
  position: relative;
  background: var(--dc-popout);
  border-radius: 10px;
  box-shadow: var(--dc-shadow);
  overflow: hidden;
  padding-bottom: 14px;
}
.banner {
  height: 96px;
  background: linear-gradient(115deg, #ff9a45 0%, #e85a12 46%, #2d356c 100%);
}
.banner svg {
  width: 100%;
  height: 100%;
  display: block;
}
.banner path {
  fill: none;
  stroke: rgba(255, 255, 255, 0.22);
  stroke-width: 2;
}
.banner path + path {
  stroke: rgba(255, 255, 255, 0.12);
}
.avatar {
  position: absolute;
  top: 52px;
  left: 14px;
  width: 80px;
  height: 80px;
  border-radius: 50%;
  border: 6px solid var(--dc-popout);
  background: var(--dc-popout);
  box-sizing: content-box;
}
.avatar svg {
  display: block;
  width: 80px;
  height: 80px;
}
.status {
  position: absolute;
  right: -2px;
  bottom: -2px;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: var(--dc-green);
  border: 5px solid var(--dc-popout);
}
.who {
  padding: 46px 16px 12px;
  font-family: var(--drpc-font-discord);
}
.name {
  font-size: 20px;
  font-weight: 700;
  color: var(--dc-text);
  line-height: 1.2;
}
.handle {
  font-size: 14px;
  color: var(--dc-text-2);
}
.activity {
  padding: 0 12px;
  display: grid;
}
/* every state is rendered; the current one fades in on top of the others */
.activity > * {
  grid-area: 1 / 1;
  opacity: 0;
  visibility: hidden;
  transform: translateY(6px);
  transition: opacity 0.3s ease, transform 0.3s ease, visibility 0s linear 0.3s;
}
.activity > .on {
  opacity: 1;
  visibility: visible;
  transform: none;
  transition-delay: 0s;
}
.chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.chips button {
  font-family: var(--vp-font-family-mono);
  font-size: 12px;
  padding: 4px 10px;
  border-radius: 4px;
  border: 1px solid var(--vp-c-divider);
  color: var(--vp-c-text-2);
  background: var(--vp-c-bg);
  transition: color 0.2s, border-color 0.2s, background-color 0.2s;
}
.chips button:hover {
  color: var(--vp-c-text-1);
  border-color: var(--vp-c-border);
}
.chips button[aria-pressed='true'] {
  color: var(--vp-c-brand-1);
  border-color: var(--vp-c-brand-1);
  background: var(--vp-c-brand-soft);
}
.chips button:focus-visible {
  outline: 2px solid var(--vp-c-brand-1);
  outline-offset: 2px;
}

</style>
