<template>
  <span v-if="manaCost" class="space-x-1">
    <i
      v-for="symbol in manaSymbols"
      :class="['ms', 'ms-cost', `ms-${symbol.toLocaleLowerCase()}`, 'justify-self-end', 'text-[1.5em]']"
      >{{ symbol }}</i
    >
  </span>
  <span v-else></span>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{ manaCost: string }>();

const manaSymbols = computed(() => {
  const manaCostMatcher = /\{([\w\/]+)\}/g;
  return Array.from(props.manaCost.matchAll(manaCostMatcher)).map((m) => m[1].replace('/', ''));
});

const hasMultipleCosts = computed(() => {
  return /\/\//.test(props.manaCost);
});
</script>
