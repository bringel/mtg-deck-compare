<template>
  <AppShell>
    <Compare />
  </AppShell>
</template>

<script setup lang="ts">
import Compare from './Compare.vue';
import AppShell from './components/AppShell.vue';
import { useTheme } from './composables/useTheme';

useTheme();
</script>
