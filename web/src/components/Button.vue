<template>
  <button
    :class="[
      'relative rounded-xs px-4 py-2',
      ...themeClasses,
      'disabled:bg-gray-500',
      'cursor-pointer',
      'min-w-20',
      'max-h-10',
      'disabled:cursor-auto'
    ]"
    :disabled="isDisabled"
  >
    <LoadingIndicator v-if="loading" />
    <span v-else>
      <slot></slot>
    </span>
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import LoadingIndicator from './LoadingIndicator.vue';

const props = withDefaults(defineProps<{ theme: 'primary' | 'secondary'; loading?: boolean; disabled?: boolean }>(), {
  theme: 'primary',
  loading: false,
  disabled: false
});

const isDisabled = computed(() => {
  return props.disabled || props.loading;
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
