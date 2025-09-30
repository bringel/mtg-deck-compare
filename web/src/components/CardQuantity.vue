<template>
  <div :class="outerClasses">
    <div :class="topClasses">{{ deckIndex + 1 }}</div>
    <div :class="bottomClasses">{{ quantity }}</div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
const props = defineProps<{ deckIndex: number; color: string; quantity: number }>();

const outerClasses = computed(() => {
  return [
    borderClass(props.color),
    'inline-flex',
    'flex-col',
    'first:rounded-l-md',
    'last:rounded-r-md',
    'overflow-hidden',
    'border',
    'items-center',
    'first:border-r-0',
    'last:border-l-0',
    'flex-1',
    'only:border-x'
  ];
});

const topClasses = computed(() => {
  return [backgroundClass(props.color), 'text-white', 'text-xs', 'min-w-full', 'text-center'];
});

const bottomClasses = computed(() => {
  return [textClass(props.color), 'px-2'];
});

function borderClass(color: string) {
  switch (color) {
    case 'orange':
      return 'border-orange-500';
    case 'cyan':
      return 'border-cyan-500';
    case 'violet':
      return 'border-violet-500';
    case 'pink':
      return 'border-pink-500';
    case 'white':
      return 'border-white';
  }
}

function backgroundClass(color: string) {
  switch (color) {
    case 'orange':
      return 'bg-orange-500';
    case 'cyan':
      return 'bg-cyan-500';
    case 'violet':
      return 'bg-violet-500';
    case 'pink':
      return 'bg-pink-500';
    case 'white':
      return 'bg-white';
  }
}

function textClass(color: string) {
  switch (color) {
    case 'orange':
      return 'text-orange-500';
    case 'cyan':
      return 'text-cyan-500';
    case 'violet':
      return 'text-violet-500';
    case 'pink':
      return 'text-pink-500';
    case 'white':
      return 'text-white';
  }
}
</script>
