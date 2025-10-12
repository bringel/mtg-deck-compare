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
  return Array.from(props.manaCost.matchAll(/\{(\w+)\}/g)).map((m) => m[1]);
});
</script>
