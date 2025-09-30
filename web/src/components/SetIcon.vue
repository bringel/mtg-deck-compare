<template>
  <i :class="classes"></i>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{ set: string; rarity: string }>();

const classes = computed(() => {
  return ['ss', `ss-${props.set}`, `ss-${props.rarity}`, 'ss-fw'];
});
</script>
