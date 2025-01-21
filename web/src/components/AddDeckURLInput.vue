<template>
  <div class="flex flex-grow-0">
    <input type="text" class="rounded-sm mr-4 w-96" v-model="url" />
    <Button @click="$emit('remove')" v-if="props.removable">Remove</Button>
  </div>
</template>

<script setup lang="ts">
import Button from './Button.vue';
const url = defineModel<string>();
defineEmits(['remove']);
const props = defineProps<{ removable: boolean }>();
</script>
