import { useFetch } from '@vueuse/core';
import { defineStore } from 'pinia';
import { reactive, ref } from 'vue';

interface Data {
  something: string;
}

export const useDeckStore = defineStore('decks', () => {
  const deckURLs = ref<Array<string>>([]);

  const deckFetchers = reactive(new Map());

  async function loadDeck(url: string) {
    if (!deckFetchers.has(url)) {
      deckURLs.value = [...deckURLs.value, url];

      const apiURL = `/api/load_deck?url=${url}`;
      const fetcher = await useFetch<Data>(apiURL).json();
      deckFetchers.set(url, fetcher);
    }
  }

  return {
    deckURLs,
    deckFetchers,
    loadDeck
  };
});
