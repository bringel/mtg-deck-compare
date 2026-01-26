<template>
  <div class="flex grow-0 flex-col gap-2 md:flex-row md:items-end">
    <Input
      v-model="url"
      id="deck-url"
      label="Enter a deck list URL"
      :hide-label="hideLabel"
      class="mr-4 w-full md:w-96"
    />
    <Button theme="primary" @click="handleAdd" :loading="loading">Add URL</Button>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import Button from './Button.vue';
import Input from './Input.vue';
const url = ref<string>('');
const emit = defineEmits<{
  addURL: [url: string];
}>();
const props = withDefaults(defineProps<{ hideLabel?: boolean; loading: boolean }>(), { hideLabel: false });

function handleAdd() {
  emit('addURL', url.value);
  url.value = '';
}
</script>
