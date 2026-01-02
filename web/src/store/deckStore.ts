import { useFetch, type UseFetchReturn } from '@vueuse/core';
import { defineStore } from 'pinia';
import { reactive, type Reactive } from 'vue';
import { type Deck } from '../types/Deck';
import { computed } from 'vue';

export const useDeckStore = defineStore('decks', () => {
  const deckFetchers = reactive(new Map<string, Reactive<UseFetchReturn<Deck>>>());
  const deckURLs = computed(() => {
    return Array.from(deckFetchers.keys());
  });

  function updateDecks(urls: string[]) {
    const currentURLs = Array.from(deckFetchers.keys());

    currentURLs.forEach((url) => {
      if (!urls.includes(url)) {
        deckFetchers.delete(url);
      }
    });

    urls.forEach((url) => {
      if (!currentURLs.includes(url)) {
        loadDeck(url);
      }
    });
  }

  function loadDeck(url: string) {
    if (!deckFetchers.has(url)) {
      const apiURL = `/api/load_deck?url=${url}`;
      const fetcher = useFetch(apiURL).json<Deck>();
      deckFetchers.set(url, reactive(fetcher));
    }
  }

  function removeDeck(url: string) {
    deckFetchers.delete(url);
  }

  return {
    deckURLs,
    deckFetchers,
    loadDeck,
    removeDeck,
    updateDecks
  };
});
