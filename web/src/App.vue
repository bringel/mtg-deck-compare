<template>
  <AppShell>
    <Compare />
  </AppShell>
</template>

<script setup lang="ts">
import { onMounted } from 'vue';
import Compare from './Compare.vue';
import AppShell from './components/AppShell.vue';
import { useTheme } from './composables/useTheme';

const { initTheme } = useTheme();

onMounted(() => {
  initTheme();
});
</script>
