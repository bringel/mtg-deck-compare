<template>
  <div class="flex flex-col space-y-2">
    <AddDeckURLInput @addURL="handleAdd" />
  </div>
  <ol class="my-4 list-inside list-decimal text-white">
    <li
      v-for="(url, index) in deckStore.deckURLs"
      :class="`underline ${underlineColors[deckColors[index]]} decoration-2 underline-offset-2`"
    >
      {{ url }}<template v-if="!deckFetchingMap[url]">&nbsp;- {{ deckNamesMap[url] }}</template>
      <template v-else
        ><LoadingIndicator class="h-[30px] w-[30px] pl-2 align-middle text-white"
      /></template>
    </li>
  </ol>
  <Button
    theme="primary"
    @click="startCompare"
    :disabled="deckStore.deckURLs.length < 2"
    :loading="comparisonStore.comparison?.isFetching"
  >
    Compare
  </Button>
  <hr class="my-4" />
  <DeckComparison />
</template>

<script setup lang="ts">
import { computed } from 'vue';
import AddDeckURLInput from './components/AddDeckURLInput.vue';

import LoadingIndicator from './components/LoadingIndicator.vue';
import Button from './components/Button.vue';
import DeckComparison from './components/DeckComparison.vue';
import { useDeckStore } from './store/deckStore';
import { useDeckComparisonStoreStore } from './store/deckComparisonStore';
import { deckColors } from './lib/deckColors';

const deckStore = useDeckStore();
const comparisonStore = useDeckComparisonStoreStore();

function handleAdd(url: string) {
  deckStore.loadDeck(url);
}

const deckNamesMap = computed<{ [url: string]: string | undefined }>(() => {
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

const underlineColors = computed(() => {
  return {
    orange: 'decoration-orange-500',
    cyan: 'decoration-cyan-500',
    violet: 'decoration-violet-500',
    pink: 'decoration-pink-500',
    white: 'decoration-white'
  };
});
</script>
