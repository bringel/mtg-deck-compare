<template>
  <AppShell>
    <div class="space-y-2 flex flex-col">
      <AddDeckURLInput @addURL="handleAdd" />
    </div>
    <ol class="list-decimal list-inside my-4 text-white">
      <li v-for="url in store.deckURLs">
        {{ url }} - {{ getDeckName(store.deckFetchers.get(url)) }}
      </li>
    </ol>
    <Button theme="primary" @click="startCompare">Compare</Button>
  </AppShell>
</template>

<script setup lang="ts">
import AddDeckURLInput from './components/AddDeckURLInput.vue';
import AppShell from './components/AppShell.vue';
import Button from './components/Button.vue';
import bingo from './lib/bingo';
import { useDeckStore } from './store/deckStore';

const store = useDeckStore();

function handleAdd(url: string) {
  store.loadDeck(url);
}

function getDeckName(deckFetcher: any) {
  if (deckFetcher?.isFetching) {
    return '';
  } else {
    return deckFetcher?.data['name'];
  }
}

function startCompare() {
  bingo.post('/api/compare_decks', {
    deckListURLs: store.deckURLs
  });
}
</script>
