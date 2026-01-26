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
      <div class="flex grow-0 flex-col gap-2 md:flex-row md:items-end">
        <Input
          v-model="deckURL"
          id="deck-url"
          label="Enter a deck list URL"
          hide-label
          class="mr-4 w-full md:w-96"
        />
        <Button theme="primary" @click="handleAdd" :loading="false">Add URL</Button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import Button from './components/Button.vue';
import Input from './components/Input.vue';
import { useDeckStore } from './store/deckStore';
import { encodeDeckURLs } from './lib/queryStringDeckURLs';

const router = useRouter();
const deckStore = useDeckStore();
const deckURL = ref('');

function handleAdd() {
  const urls = encodeDeckURLs([deckURL.value]);
  deckURL.value = '';
  router.push({ path: '/compare', query: { deckURLs: urls } });
}
</script>
