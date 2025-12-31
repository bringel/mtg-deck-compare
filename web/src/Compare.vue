<template>
  <AddDeckURLInput @addURL="handleAdd" />

  <ol class="my-4 ml-4 max-w-fit list-outside list-decimal space-y-2 dark:text-white">
    <li
      v-for="(url, index) in deckStore.deckURLs"
      :class="`underline ${underlineColors[deckColors[index]]} decoration-2 underline-offset-2`"
    >
      <div class="flex items-center" v-if="!deckFetchingMap[url]">
        <a class="flex grow cursor-pointer flex-col" :href="url" rel="noopener noreferrer" target="_blank">
          <span>{{ deckNamesMap[url]?.name }} by {{ deckNamesMap[url]?.author }}</span>
          <span> {{ url }}</span>
        </a>
        <XCircleIcon class="ml-2 inline-block size-6 shrink-0 cursor-pointer text-red-700" @click="removeURL(url)" />
      </div>
      <LoadingIndicator v-else class="h-[30px] w-[30px] pl-2 align-middle dark:text-white" />
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
