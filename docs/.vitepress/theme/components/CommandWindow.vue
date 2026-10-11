<script setup lang="ts">
// What `drpc` prints. The pause and hide names links work, like they do in MATLAB.
import { computed, ref } from 'vue'

const names = ref(true)
const paused = ref(false)
const last = ref<{ cmd: string; msg: string } | null>(null)

const showing = computed(() =>
  paused.value
    ? null
    : names.value
      ? ['Editing pid_controller.m', 'Function · Line 42 of 142']
      : ['Editing a function', 'Line 42 of 142']
)

function togglePause() {
  paused.value = !paused.value
  last.value = paused.value
    ? { cmd: 'drpc pause', msg: 'Discord RPC paused.' }
    : { cmd: 'drpc resume', msg: 'Discord RPC resumed.' }
}
function toggleNames() {
  names.value = !names.value
  last.value = names.value
    ? { cmd: 'drpc names on', msg: 'File names are visible on Discord.' }
    : { cmd: 'drpc names off', msg: 'File names are hidden on Discord.' }
}
</script>

<template>
  <div class="window">
    <div class="bar">
      <span class="dots" aria-hidden="true"><i /><i /><i /></span>
      <span class="title">Command Window</span>
    </div>
    <pre class="out" aria-live="polite"><template v-if="last"><span class="p">&gt;&gt;</span> {{ last.cmd }}
{{ last.msg }}
</template><span class="p">&gt;&gt;</span> drpc

  <b>Discord Rich Presence</b> for MATLAB  v1.1.0

  <span class="k">Discord      </span> {{ paused ? 'Paused' : 'Connected as Ada' }}
<template v-if="showing">  <span class="k">Showing      </span> {{ showing[0] }}
                {{ showing[1] }}
</template>  <span class="k">Settings     </span> <u>config.json</u>  (names {{ names ? 'on' : 'off' }}, idle after 10 min)

  <button type="button" @click="togglePause">{{ paused ? 'resume' : 'pause' }}</button>   <button type="button" @click="toggleNames">{{ names ? 'hide names' : 'show names' }}</button>   <u>preview</u>   <u>restart</u>   <u>stop</u>   <u>docs</u>

<span class="p">&gt;&gt;</span> <span class="cursor" /></pre>
    <p class="hint">Try the <em>pause</em> and <em>hide names</em> links.</p>
  </div>
</template>

<style scoped>
.window {
  min-width: 0;
  border: 1px solid var(--drpc-panel-edge);
  border-radius: 6px;
  background: var(--drpc-cmd-bg);
  overflow: hidden;
  box-shadow: 0 30px 60px -30px rgba(0, 0, 0, 0.45);
}
.bar {
  display: flex;
  align-items: center;
  gap: 12px;
  height: 36px;
  padding: 0 14px;
  border-bottom: 1px solid var(--drpc-panel-edge);
  background: var(--vp-c-bg-soft);
}
.dots {
  display: flex;
  gap: 6px;
}
.dots i {
  width: 9px;
  height: 9px;
  border-radius: 50%;
  background: var(--vp-c-border);
}
.title {
  font-family: var(--vp-font-family-mono);
  font-size: 12px;
  color: var(--vp-c-text-3);
}
.out {
  margin: 0;
  padding: 18px 20px 20px;
  font-family: var(--vp-font-family-mono);
  font-size: 13.5px;
  line-height: 1.6;
  color: var(--drpc-cmd-text);
  white-space: pre;
  overflow-x: auto;
  min-height: 300px;
}
.p {
  color: var(--drpc-cmd-prompt);
}
.k {
  color: var(--drpc-cmd-dim);
}
b {
  font-weight: 700;
}
u,
button {
  color: var(--drpc-cmd-link);
  text-decoration: underline;
  text-underline-offset: 2px;
}
button {
  font: inherit;
  padding: 0;
  cursor: pointer;
}
button:hover {
  text-decoration-thickness: 2px;
}
button:focus-visible {
  outline: 2px solid var(--vp-c-brand-1);
  outline-offset: 2px;
  border-radius: 2px;
}
.cursor {
  display: inline-block;
  width: 8px;
  height: 1.1em;
  vertical-align: -0.2em;
  background: var(--drpc-cmd-text);
  animation: blink 1.1s steps(1) infinite;
}
@keyframes blink {
  50% {
    opacity: 0;
  }
}
.hint {
  margin: 0;
  padding: 10px 20px;
  border-top: 1px solid var(--drpc-panel-edge);
  font-size: 13px;
  color: var(--vp-c-text-3);
}
.hint em {
  font-style: normal;
  color: var(--drpc-cmd-link);
}
</style>
