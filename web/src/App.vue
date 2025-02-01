<template>
  <AppShell>
    <div class="space-y-2 flex flex-col">
      <AddDeckURLInput @addURL="handleAdd" />
    </div>
    <ol class="list-decimal list-inside my-4 text-white">
      <li v-for="url in deckURLs">
        {{ url }}
      </li>
    </ol>
    <Button @click="startCompare">Compare</Button>
  </AppShell>
</template>

<script setup lang="ts">
import AddDeckURLInput from './components/AddDeckURLInput.vue';
import AppShell from './components/AppShell.vue';
import { ref } from 'vue';
import Button from './components/Button.vue';
import bingo from './lib/bingo';

const deckURLs = ref([]);

function handleAdd(url: string) {
  deckURLs.value.push(url);
}

function startCompare() {
  bingo.post('/api/compare_decks', {
    deckListURLs: deckURLs.value
  });
}
</script>
