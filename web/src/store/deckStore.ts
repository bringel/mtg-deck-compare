import { useFetch, type UseFetchReturn } from '@vueuse/core';
import { defineStore } from 'pinia';
import { reactive, ref, type Reactive } from 'vue';
import { type Deck } from '../types/Deck';

export const useDeckStore = defineStore('decks', () => {
  const deckURLs = ref<Array<string>>([]);

  const deckFetchers = reactive(
    new Map<string, Reactive<UseFetchReturn<Deck>> | { isFetching: boolean }>()
  );

  async function loadDeck(url: string) {
    if (!deckFetchers.has(url)) {
      deckFetchers.set(url, { isFetching: true });
      deckURLs.value = [...deckURLs.value, url];

      const apiURL = `/api/load_deck?url=${url}`;
      const fetcher = await useFetch(apiURL).json<Deck>();
      deckFetchers.set(url, reactive(fetcher));
    }
  }

  return {
    deckURLs,
    deckFetchers,
    loadDeck
  };
});
