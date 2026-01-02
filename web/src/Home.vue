<template>
  <div class="mx-auto max-w-3xl">
    <div class="text-background-700 mb-8 space-y-4 text-lg dark:text-gray-300">
      <p>Level up your next brew by comparing multiple Magic: The Gathering deck lists side-by-side.</p>

      <p>
        Simply paste deck URLs from popular deckbuilding sites like Moxfield, Archidekt, Aetherhub, MTGGoldfish, and
        more. This tool will analyze the decks and show you:
      </p>

      <ul class="ml-6 list-disc space-y-2">
        <li>Cards that appear in all decks</li>
        <li>Unique cards in each deck</li>
        <li>Cards that appear in multiple decks</li>
        <li>Card quantities across all decks</li>
      </ul>

      <p>
        Perfect for refining your own builds, analyzing the meta, or finding the card that's missing from your sideboard
      </p>
    </div>

    <div class="bg-background-50 dark:bg-background-800 rounded-lg p-6">
      <h2 class="text-background-800 font-display mb-4 text-xl font-semibold dark:text-white">Get Started</h2>
      <p class="text-background-700 mb-4 dark:text-gray-300">Add your first deck URL to begin comparing:</p>
      <AddDeckURLInput hideLabel @addURL="handleAdd" />
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
