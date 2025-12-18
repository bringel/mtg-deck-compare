<template>
  <AppShell>
    <router-view />
  </AppShell>
</template>

<script setup lang="ts">
import AppShell from './components/AppShell.vue';
import { useTheme } from './composables/useTheme';

useTheme();
</script>
