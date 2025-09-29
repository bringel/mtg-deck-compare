<template>
  <template v-if="manaCost">
    <i
      v-for="symbol in manaSymbols"
      :class="['ms', 'ms-cost', `ms-${symbol.toLocaleLowerCase()}`, 'justify-self-end']"
      >{{ symbol }}</i
    >
  </template>
  <template v-else>
    <span></span>
  </template>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{ manaCost: string }>();

const manaSymbols = computed(() => {
  return Array.from(props.manaCost.matchAll(/\{(\w+)\}/g)).map((m) => m[1]);
});
</script>
