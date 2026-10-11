<script setup lang="ts">
// The large image drpc shows on Discord: the orange trace on navy.
import { useId } from 'vue'
const id = useId()
</script>

<template>
  <svg class="matlab-art" viewBox="0 0 100 100" role="img" aria-label="MATLAB">
    <defs>
      <linearGradient :id="`bg-${id}`" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="#28336a" />
        <stop offset="1" stop-color="#141a35" />
      </linearGradient>
      <linearGradient :id="`tr-${id}`" x1="0" y1="0" x2="1" y2="0">
        <stop offset="0" stop-color="#ffb347" />
        <stop offset="1" stop-color="#ff741a" />
      </linearGradient>
    </defs>
    <rect width="100" height="100" rx="22" :fill="`url(#bg-${id})`" />
    <path
      d="M18 51 C 23 36, 28 25, 34 25 C 43 25, 50 72, 61 72 C 67 72, 72 62, 80 47"
      fill="none"
      :stroke="`url(#tr-${id})`"
      stroke-width="8.5"
      stroke-linecap="round"
    />
  </svg>
</template>

<style scoped>
.matlab-art {
  display: block;
  width: 100%;
  height: 100%;
}
</style>
