<template>
  <div class="flex min-h-[60vh] flex-col items-center justify-center px-4">
    <div class="w-full max-w-2xl text-center">
      <h1 class="mb-6 text-4xl font-bold text-gray-900 dark:text-white md:text-5xl">
        MTG Deck Compare
      </h1>

      <p class="mb-8 text-xl text-gray-700 dark:text-gray-300">
        Instantly compare multiple MTG deck lists side-by-side by dropping in URLs from your
        favorite deckbuilding sites. See what they share, what sets them apart, and make smarter
        decisions for analyzing the meta or refining your own builds.
      </p>

      <div class="mb-4">
        <p class="mb-3 text-lg font-semibold text-gray-800 dark:text-gray-200">
          Get started by entering your first deck URL:
        </p>
        <form @submit.prevent="handleSubmit" class="flex flex-col gap-3 md:flex-row">
          <input
            v-model="deckUrl"
            type="url"
            placeholder="https://moxfield.com/decks/..."
            class="flex-1 rounded-lg border border-gray-300 px-4 py-3 text-base focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white dark:placeholder-gray-400"
            required
          />
          <Button
            type="submit"
            theme="primary"
            :disabled="!deckUrl"
            class="md:w-auto"
          >
            Start Comparing
          </Button>
        </form>
      </div>

      <div class="mt-8 text-sm text-gray-600 dark:text-gray-400">
        <p class="mb-2">Supported sites:</p>
        <p>Moxfield • Archidekt • Aetherhub • Deckstats • MTGGoldfish</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useDeckStore } from '../store/deckStore';
import Button from '../components/Button.vue';

const router = useRouter();
const deckStore = useDeckStore();
const deckUrl = ref('');

function handleSubmit() {
  if (deckUrl.value) {
    // Load the deck and navigate to compare view
    deckStore.loadDeck(deckUrl.value);
    router.push('/compare');
  }
}
</script>
