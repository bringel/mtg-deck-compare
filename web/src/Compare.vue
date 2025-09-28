<template>
  <div class="space-y-2 flex flex-col">
    <AddDeckURLInput @addURL="handleAdd" />
  </div>
  <ol class="list-decimal list-inside my-4 text-white">
    <li v-for="url in deckStore.deckURLs">
      {{ url }}<template v-if="!deckFetchingMap[url]">&nbsp;- {{ deckNamesMap[url] }}</template>
    </li>
  </ol>
  <Button theme="primary" @click="startCompare" :disabled="deckStore.deckURLs.length < 2">
    Compare
  </Button>
  <hr class="mt-4" />
  <DeckComparison />
</template>

<script setup lang="ts">
import { computed } from 'vue';
import AddDeckURLInput from './components/AddDeckURLInput.vue';

import Button from './components/Button.vue';
import DeckComparison from './components/DeckComparison.vue';
import { useDeckStore } from './store/deckStore';
import { useDeckComparisonStoreStore } from './store/deckComparisonStore';

const deckStore = useDeckStore();
const comparisonStore = useDeckComparisonStoreStore();

function handleAdd(url: string) {
  deckStore.loadDeck(url);
}

const deckNamesMap = computed<{ [url: string]: string }>(() => {
  return Object.fromEntries(
    Array.from(deckStore.deckFetchers.keys()).map((k: string) => {
      if (deckFetchingMap.value[k]) {
        return [k, ''];
      } else {
        // @ts-ignore - object will have a data property if the fetcher isn't loading
        return [k, (deckStore.deckFetchers.get(k)?.data ?? {})['name']];
      }
    })
  );
});

const deckFetchingMap = computed<{ [url: string]: boolean }>(() => {
  return Object.fromEntries(
    Array.from(deckStore.deckFetchers.keys()).map((k) => {
      const fetcher = deckStore.deckFetchers.get(k);
      return [k, fetcher?.isFetching ?? true];
    })
  );
});

function startCompare() {
  comparisonStore.getComparison();
}
</script>
