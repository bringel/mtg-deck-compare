<template>
  <button
    :class="['rounded-sm px-4 py-2 active:border-b-0 active:top-1 relative', ...themeClasses]"
  >
    <slot></slot>
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = withDefaults(defineProps<{ theme: 'primary' | 'secondary' }>(), {
  theme: 'primary'
});

const themeClasses = computed(() => {
  switch (props.theme) {
    case 'primary':
      return ['bg-primary-500', 'border-primary-700'];
    case 'secondary':
      return ['bg-secondary-500', 'border-secondary-700'];
    default:
      return [];
  }
});
</script>
