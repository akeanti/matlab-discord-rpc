<script setup lang="ts">
const nodes = [
  { id: 'timer', title: 'MATLAB timer', sub: 'fires every 2 s' },
  { id: 'drpc', title: 'drpc.m', sub: 'reads the Editor, the window in front, Simulink, the debugger' },
  { id: 'bridge', title: 'C# bridge', sub: 'own thread, sends a change at most every 5 s' },
  { id: 'pipe', title: '\\\\.\\pipe\\discord-ipc-0', sub: "Discord's local named pipe" },
  { id: 'discord', title: 'Discord', sub: 'your profile, member list and DMs' }
]
const wires = ['snapshot', 'activity', 'SET_ACTIVITY', '']
</script>

<template>
  <div class="pipeline" role="img" aria-label="MATLAB timer every 2 seconds, to drpc.m, to the C# bridge thread, over Discord's named pipe, to Discord. A watchdog on the bridge shows Running when MATLAB stops reporting.">
    <template v-for="(n, i) in nodes" :key="n.id">
      <div class="node" :class="n.id" :style="{ gridColumn: 2 * i + 1 }">
        <div class="title">{{ n.title }}</div>
        <div class="sub">{{ n.sub }}</div>
      </div>
      <div v-if="i < nodes.length - 1" class="wire" :style="{ gridColumn: 2 * i + 2 }">
        <span class="line" />
        <span class="packet" :style="{ animationDelay: `${i * 0.45}s` }" />
        <span v-if="wires[i]" class="wire-label">{{ wires[i] }}</span>
      </div>
    </template>
    <div class="watchdog">
      <span class="tag">watchdog</span>
      No heartbeat for 4 s while MATLAB is busy, or 15 s at all: the bridge switches you to
      <strong>Running…</strong> on its own, timed from when MATLAB went quiet.
    </div>
  </div>
</template>

<style scoped>
.pipeline {
  margin-top: 48px;
  display: grid;
  grid-template-columns: minmax(0, 1fr) 92px minmax(0, 1.25fr) 92px minmax(0, 1.2fr) 92px minmax(0, 1.2fr) 40px minmax(0, 0.9fr);
  grid-template-rows: auto auto;
  align-items: stretch;
  row-gap: 0;
}
.node {
  grid-row: 1;
  min-width: 0;
  padding: 16px;
  border: 1px solid var(--drpc-panel-edge);
  border-radius: 6px;
  background: var(--drpc-panel);
}
.title {
  font-family: var(--vp-font-family-mono);
  font-size: 13.5px;
  font-weight: 600;
  color: var(--vp-c-text-1);
  overflow-wrap: anywhere;
}
.sub {
  margin-top: 6px;
  font-size: 13.5px;
  line-height: 1.5;
  color: var(--vp-c-text-2);
}
.node.bridge {
  border-color: var(--vp-c-brand-1);
  box-shadow: 0 0 0 4px var(--vp-c-brand-soft);
}
.node.bridge .title {
  color: var(--vp-c-brand-1);
}
.node.discord {
  border-color: var(--dc-blurple);
}
.node.discord .title {
  color: var(--dc-blurple);
}
:global(.dark) .node.discord .title {
  color: #9ea6ff;
}

.wire {
  grid-row: 1;
  position: relative;
  align-self: center;
  height: 40px;
}
.line {
  position: absolute;
  left: 0;
  right: 0;
  top: 50%;
  height: 1px;
  background: var(--vp-c-border);
}
.packet {
  position: absolute;
  top: calc(50% - 3px);
  left: 0;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--drpc-orange);
  box-shadow: 0 0 10px var(--drpc-orange);
  animation: travel 2s linear infinite;
}
.wire-label {
  position: absolute;
  left: 50%;
  bottom: calc(50% + 6px);
  transform: translateX(-50%);
  font-family: var(--vp-font-family-mono);
  font-size: 10.5px;
  color: var(--vp-c-text-3);
  white-space: nowrap;
}
@keyframes travel {
  from {
    left: 0;
    opacity: 0;
  }
  15% {
    opacity: 1;
  }
  85% {
    opacity: 1;
  }
  to {
    left: calc(100% - 6px);
    opacity: 0;
  }
}

.watchdog {
  grid-row: 2;
  grid-column: 3 / 8;
  position: relative;
  margin-top: 36px;
  padding: 14px 16px;
  border: 1px dashed var(--vp-c-border);
  border-radius: 6px;
  font-size: 14px;
  line-height: 1.6;
  color: var(--vp-c-text-2);
}
.watchdog::before {
  content: '';
  position: absolute;
  left: 50%;
  top: -37px;
  height: 36px;
  border-left: 1px dashed var(--vp-c-brand-1);
}
.watchdog strong {
  color: var(--vp-c-text-1);
}
.tag {
  font-family: var(--vp-font-family-mono);
  font-size: 11.5px;
  padding: 2px 7px;
  margin-right: 8px;
  border-radius: 4px;
  background: var(--vp-c-brand-soft);
  color: var(--vp-c-brand-1);
}

@media (max-width: 960px) {
  .pipeline {
    grid-template-columns: minmax(0, 1fr);
    max-width: 460px;
  }
  .node,
  .wire,
  .watchdog {
    grid-column: 1 !important;
    grid-row: auto;
  }
  .wire {
    height: 44px;
  }
  .line {
    left: 24px;
    right: auto;
    top: 0;
    bottom: 0;
    width: 1px;
    height: auto;
  }
  .packet {
    left: 21px;
    animation-name: drop;
  }
  .wire-label {
    left: 40px;
    bottom: auto;
    top: 50%;
    transform: translateY(-50%);
  }
  .watchdog {
    order: 0;
    margin-top: 16px;
  }
  .watchdog::before {
    display: none;
  }
  @keyframes drop {
    from {
      top: 0;
      opacity: 0;
    }
    15% {
      opacity: 1;
    }
    85% {
      opacity: 1;
    }
    to {
      top: calc(100% - 6px);
      opacity: 0;
    }
  }
}
</style>
