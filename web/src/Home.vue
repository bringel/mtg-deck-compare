<template>
  <div class="mx-auto max-w-3xl">
    <h1 class="mb-6 text-4xl font-bold text-background-800 dark:text-white">
      MTG Deck Compare
    </h1>

    <div class="mb-8 space-y-4 text-lg text-background-700 dark:text-gray-300">
      <p>
        Compare multiple Magic: The Gathering deck lists side-by-side to see what they share and what sets them apart.
      </p>

      <p>
        Simply paste deck URLs from popular deckbuilding sites like Moxfield, Archidekt, Aetherhub, MTGGoldfish, and more.
        Our tool will analyze the decks and show you:
      </p>

      <ul class="ml-6 list-disc space-y-2">
        <li>Cards that appear in all decks</li>
        <li>Cards that appear in multiple decks</li>
        <li>Unique cards in each deck</li>
        <li>Card quantities across all decks</li>
      </ul>

      <p>
        Perfect for analyzing the meta, refining your own builds, or finding tech choices that make the difference.
      </p>
    </div>

    <div class="rounded-lg bg-background-50 p-6 dark:bg-background-800">
      <h2 class="mb-4 text-xl font-semibold text-background-800 dark:text-white">
        Get Started
      </h2>
      <p class="mb-4 text-background-700 dark:text-gray-300">
        Add your first deck URL to begin comparing:
      </p>
      <AddDeckURLInput @addURL="handleAdd" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router';
import AddDeckURLInput from './components/AddDeckURLInput.vue';
import { useDeckStore } from './store/deckStore';

const router = useRouter();
const deckStore = useDeckStore();

function handleAdd(url: string) {
  deckStore.loadDeck(url);
  router.push('/compare');
}
</script>
