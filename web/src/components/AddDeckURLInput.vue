<template>
  <div class="flex grow-0 flex-col gap-2 md:flex-row md:items-end">
    <div class="flex flex-col">
      <label for="deck-url" :class="['dark:text-white', { 'sr-only': props.hideLabel }]">Enter a deck list URL</label>
      <input id="deck-url" type="text" class="mr-4 w-full rounded-xs md:w-96" v-model="url" />
    </div>
    <Button theme="primary" @click="handleAdd">Add URL</Button>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import Button from './Button.vue';
const url = ref<string>('');
const emit = defineEmits<{
  addURL: [url: string];
}>();
const props = withDefaults(defineProps<{ hideLabel?: boolean }>(), { hideLabel: false });

function handleAdd() {
  emit('addURL', url.value);
  url.value = '';
}
</script>
