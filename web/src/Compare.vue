<template>
  <AddDeckURLInput @addURL="handleAdd" />

  <ol class="my-4 flex list-inside list-decimal flex-wrap gap-2 dark:text-white">
    <li
      v-for="(url, index) in deckStore.deckURLs"
      :key="url"
      :class="`rounded-full border-2 ${borderColors[deckColors[index]]} bg-gray-100 px-4 py-1 dark:bg-gray-800`"
    >
      <div class="inline-flex items-center gap-2" v-if="!deckFetchingMap[url]">
        <a class="flex cursor-pointer flex-col" :href="url" rel="noopener noreferrer" target="_blank">
          <span class="text-sm font-medium">{{ deckNamesMap[url]?.name }} by {{ deckNamesMap[url]?.author }}</span>
          <span class="text-xs opacity-70">{{ url }}</span>
        </a>
        <XCircleIcon class="inline-block size-5 shrink-0 cursor-pointer hover:text-red-700" @click="removeURL(url)" />
      </div>
      <div class="inline-flex items-center gap-2" v-else>
        <LoadingIndicator class="h-[30px] w-[30px] dark:text-white" />
      </div>
    </li>
  </ol>
  <Button
    theme="primary"
    @click="startCompare"
    :disabled="deckStore.deckURLs.length < 2"
    :loading="comparisonStore.comparison?.isFetching"
    class="w-full md:w-[unset]"
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
import { XCircleIcon } from '@heroicons/vue/24/outline';

const deckStore = useDeckStore();
const comparisonStore = useDeckComparisonStoreStore();

function handleAdd(url: string) {
  deckStore.loadDeck(url);
}

function removeURL(url: string) {
  deckStore.removeDeck(url);
}

const deckNamesMap = computed<{ [url: string]: { name: string; author: string } | undefined }>(() => {
  return Object.fromEntries(
    Array.from(deckStore.deckFetchers.keys()).map((k: string) => {
      if (deckFetchingMap.value[k]) {
        return [k, { name: '', author: '' }];
      } else {
        const data = deckStore.deckFetchers.get(k)?.data ?? {};
        // @ts-ignore - object will have a data property if the fetcher isn't loading
        return [k, { name: data['name'], author: data['author'] }];
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

const borderColors = computed(() => {
  return {
    orange: 'border-orange-500',
    cyan: 'border-cyan-500',
    violet: 'border-violet-500',
    pink: 'border-pink-500',
    white: 'border-white'
  };
});
</script>
