<template>
  <div class="space-y-2 flex flex-col">
    <AddDeckURLInput @addURL="handleAdd" />
  </div>
  <ol class="list-decimal list-inside my-4 text-white">
    <li v-for="url in store.deckURLs">{{ url }} - {{ deckNamesMap[url] }}</li>
  </ol>
  <Button theme="primary" @click="startCompare" :disabled="store.deckURLs.length < 2"
    >Compare</Button
  >
</template>

<script setup lang="ts">
import { computed } from 'vue';
import AddDeckURLInput from './components/AddDeckURLInput.vue';

import Button from './components/Button.vue';
import bingo from './lib/bingo';
import { useDeckStore } from './store/deckStore';

const store = useDeckStore();

function handleAdd(url: string) {
  store.loadDeck(url);
}

const deckNamesMap = computed(() => {
  return Object.fromEntries(
    Array.from(store.deckFetchers.keys()).map((k) => {
      const fetcher = store.deckFetchers.get(k);
      if (fetcher.isFetching) {
        return [k, ''];
      } else {
        return [k, fetcher.data['name']];
      }
    })
  );
});

function startCompare() {
  bingo.post('/api/compare_decks', {
    deckListURLs: store.deckURLs
  });
}
</script>
