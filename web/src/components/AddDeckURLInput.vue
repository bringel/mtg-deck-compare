<template>
  <div class="flex grow-0">
    <input type="text" class="mr-4 w-96 rounded-xs" v-model="url" />
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
