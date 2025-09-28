import { acceptHMRUpdate, defineStore } from 'pinia';
import { reactive, type Reactive } from 'vue';
import { useFetch, type UseFetchReturn } from '@vueuse/core';

import { type DeckComparison } from '../types/DeckComparison';

export const useDeckComparisonStoreStore = defineStore('deckComparisonStore', () => {
  const comparisonsMap = reactive(
    new Map<string, Reactive<UseFetchReturn<DeckComparison> | { isFetching: boolean }>>()
  );

  async function getComparison(deckURLs: Array<string>) {
    const key = comparisonKey(deckURLs);
    if (!comparisonsMap.has(key)) {
      comparisonsMap.set(key, { isFetching: true });
      const fetcher = await useFetch('/api/compare_decks')
        .post({ deckListURLs: deckURLs })
        .json<DeckComparison>();

      comparisonsMap.set(key, reactive(fetcher));
    }
  }
  return { comparisonsMap, getComparison };
});

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useDeckComparisonStoreStore, import.meta.hot));
}

export function comparisonKey(deckURLs: Array<string>) {
  return deckURLs.join('$');
}
