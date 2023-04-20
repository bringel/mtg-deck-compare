<template>
  <div>
    <input type="text" class="rounded-sm mr-4" v-model="url" />
    <Button>Add</Button>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import Button from './Button.vue'

const url = ref('')

</script>
