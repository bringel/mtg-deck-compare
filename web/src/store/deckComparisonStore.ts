import { acceptHMRUpdate, defineStore } from 'pinia';
import { ref } from 'vue';
import { useFetch, type UseFetchReturn } from '@vueuse/core';

import { type DeckComparison } from '../types/DeckComparison';
import { useDeckStore } from './deckStore';

export const useDeckComparisonStoreStore = defineStore('deckComparisonStore', () => {
  const deckStore = useDeckStore();

  const comparison = ref<UseFetchReturn<DeckComparison> | null>(null);

  function getComparison() {
    comparison.value = useFetch('/api/compare_decks')
      .post({ deckListURLs: deckStore.deckURLs })
      .json<DeckComparison>();
  }
  return { comparison, getComparison };
});

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useDeckComparisonStoreStore, import.meta.hot));
}
