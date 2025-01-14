<template>
  <div>
    <input type="text" class="rounded-sm mr-4" v-model="url" />
    <Button @click="loadDeck">Add</Button>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import Button from './Button.vue';

const url = ref('');

function loadDeck() {
  fetch('/api/load_deck', {
    method: 'POST',
    body: JSON.stringify({
      url: url
    }),
    headers: {
      'Content-Type': 'application/json'
    }
  });
}
</script>
