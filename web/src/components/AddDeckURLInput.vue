<template>
  <div class="flex grow-0 flex-col gap-2 md:flex-row">
    <input type="text" class="mr-4 w-full rounded-xs md:w-96" v-model="url" />
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

function handleAdd() {
  emit('addURL', url.value);
  url.value = '';
}
</script>
