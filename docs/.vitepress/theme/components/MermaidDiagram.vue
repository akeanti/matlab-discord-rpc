<script setup lang="ts">
// Renders ```mermaid fences on the client, in the site's colors.
import { onMounted, ref, watch, useId } from 'vue'
import { useData } from 'vitepress'

const props = defineProps<{ code: string }>()
const { isDark } = useData()
const svg = ref('')
const id = 'mmd' + useId().replace(/[^a-zA-Z0-9]/g, '')

async function render() {
  const { default: mermaid } = await import('mermaid')
  // labels are measured when drawn, so the web font has to be there first
  await document.fonts.ready
  const dark = isDark.value
  mermaid.initialize({
    startOnLoad: false,
    securityLevel: 'strict',
    theme: 'base',
    fontFamily: "'IBM Plex Sans', system-ui, sans-serif",
    flowchart: { padding: 14, nodeSpacing: 40, rankSpacing: 48 },
    themeVariables: {
      darkMode: dark,
      background: 'transparent',
      primaryColor: dark ? '#131829' : '#ffffff',
      primaryBorderColor: dark ? '#ff8a3d' : '#c24e08',
      primaryTextColor: dark ? '#e8eaf3' : '#12172a',
      lineColor: dark ? '#6b7394' : '#7a8099',
      edgeLabelBackground: dark ? '#0b0e18' : '#fbfbfd',
      fontSize: '14px'
    }
  })
  const { svg: out } = await mermaid.render(id + (dark ? 'd' : 'l'), decodeURIComponent(props.code))
  svg.value = out
}

onMounted(render)
watch(isDark, render)
</script>

<template>
  <div class="mermaid-diagram" v-html="svg" />
</template>

<style scoped>
.mermaid-diagram {
  margin: 20px 0;
  padding: 20px;
  border: 1px solid var(--vp-c-divider);
  border-radius: 6px;
  background: var(--vp-c-bg-soft);
  overflow-x: auto;
  min-height: 120px;
  display: flex;
  justify-content: center;
}
.mermaid-diagram :deep(svg) {
  max-width: 100%;
  height: auto;
}
/* mermaid sizes its labels at line-height 1.5; the doc styles would stretch them */
.mermaid-diagram :deep(foreignObject p),
.mermaid-diagram :deep(foreignObject span),
.mermaid-diagram :deep(foreignObject div) {
  line-height: 1.5;
  margin: 0;
}
</style>
