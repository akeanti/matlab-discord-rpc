<script setup lang="ts">
import { computed } from 'vue'
import MatlabArt from './MatlabArt.vue'
import { elapsedText, type PresenceState } from '../states'

const props = defineProps<{ s: PresenceState; elapsed: number }>()
const time = computed(() => elapsedText(props.s.elapsed + props.elapsed))
</script>

<template>
  <div class="dc-card">
    <div class="dc-head">Playing</div>
    <div class="dc-body">
      <div class="dc-art">
        <MatlabArt />
        <img v-if="s.icon" :src="s.icon" class="dc-small" :title="s.hover" alt="" width="26" height="26" />
      </div>
      <div class="dc-text">
        <div class="dc-name">MATLAB</div>
        <div class="dc-line">{{ s.details }}</div>
        <div v-if="s.state" class="dc-line">{{ s.state }}</div>
        <div class="dc-time">
          <svg viewBox="0 0 24 16" aria-hidden="true">
            <path
              fill="currentColor"
              fill-rule="evenodd"
              d="M6.5 1h11A5.5 5.5 0 0 1 23 6.5v3A5.5 5.5 0 0 1 17.5 15h-11A5.5 5.5 0 0 1 1 9.5v-3A5.5 5.5 0 0 1 6.5 1Zm.5 4v2H5v2h2v2h2V9h2V7H9V5H7Zm9 1a1.25 1.25 0 1 0 0 2.5A1.25 1.25 0 0 0 16 6Zm2.5 2.5a1.25 1.25 0 1 0 0 2.5 1.25 1.25 0 0 0 0-2.5Z"
            />
          </svg>
          <span>{{ time }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.dc-card {
  background: var(--dc-card);
  border-radius: 8px;
  padding: 12px 14px 14px;
  color: var(--dc-text);
  font-family: var(--drpc-font-discord);
  text-align: left;
  min-width: 0;
}
.dc-head {
  font-size: 12px;
  font-weight: 600;
  color: var(--dc-header);
  margin-bottom: 10px;
}
.dc-body {
  display: flex;
  gap: 12px;
  align-items: center;
  min-width: 0;
}
.dc-art {
  position: relative;
  flex: 0 0 auto;
  width: 64px;
  height: 64px;
}
.dc-small {
  position: absolute;
  right: -7px;
  bottom: -7px;
  width: 26px;
  height: 26px;
  border-radius: 50%;
  border: 3px solid var(--dc-card);
  background: var(--dc-card);
  box-sizing: content-box;
}
.dc-text {
  min-width: 0;
  line-height: 1.3;
}
.dc-name {
  font-weight: 700;
  font-size: 14px;
}
.dc-line {
  font-size: 13.5px;
  color: var(--dc-text-2);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.dc-time {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 2px;
  font-size: 13px;
  font-weight: 600;
  color: var(--dc-green);
  font-variant-numeric: tabular-nums;
}
.dc-time svg {
  width: 17px;
  height: 12px;
}
</style>
