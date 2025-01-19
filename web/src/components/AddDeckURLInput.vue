<template>
  <div>
    <input type="text" class="rounded-sm mr-4" v-model="url" />
    <Button @click="$emit('remove')">Remove</Button>
  </div>
</template>

<script setup lang="ts">
import Button from './Button.vue';
const url = defineModel<string>();
defineEmits(['remove']);
</script>
