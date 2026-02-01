<template>
  <ErrorDialog :is-open="errorDialogOpen" @close="handleErrorDialogClose">
    <template #title>Error loading deck list</template>
    <template #body>
      Sorry! We're having some trouble loading the deck from the URL you entered. While we work on fixing it, you can
      enter the deck list manually, or try again in a little bit
      <br />
      <hr />
      <a :href="currentLoadingURL" class="underline">{{ currentLoadingURL }}</a>
    </template>
    <template #buttons>
      <Button theme="error" @click="switchToManualAdd">Add Manually</Button>
      <Button theme="error" @click="handleErrorDialogClose">Close</Button>
    </template>
  </ErrorDialog>
  <ManualDeckModal :open="manualDeckModalOpen" @close="manualDeckModalOpen = false" />
  <div class="flex grow-0 flex-col gap-2 md:flex-row md:items-end">
    <Input v-model="deckURL" id="deck-url" label="Enter a deck list URL" class="mr-4 w-full md:w-96" />
    <Button theme="primary" @click="handleAdd" :loading="currentLoadingURL !== ''">Add URL</Button>
    <Button @click="manualDeckModalOpen = true" theme="primary">Add Manual Deck</Button>
  </div>

  <ol class="my-4 flex list-inside list-decimal flex-wrap gap-2 dark:text-white">
    <li
      v-for="(url, index) in deckStore.deckURLs"
      :key="url"
      :class="`rounded-full border-2 ${borderColors[deckColors[index]]} bg-gray-100 px-4 py-1 dark:bg-gray-800`"
    >
      <div class="inline-flex items-center gap-2" v-if="!deckFetchingMap[url]">
        <a class="flex cursor-pointer flex-col" :href="url" rel="noopener noreferrer" target="_blank">
          <span class="text-sm font-medium">{{ deckNamesMap[url]?.name }} by {{ deckNamesMap[url]?.author }}</span>
          <span class="text-xs opacity-70">{{ url }}</span>
        </a>
        <XCircleIcon class="inline-block size-5 shrink-0 cursor-pointer hover:text-red-700" @click="removeURL(url)" />
      </div>
      <div class="inline-flex items-center gap-2" v-else>
        <LoadingIndicator class="h-[30px] w-[30px] dark:text-white" />
      </div>
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
import { XCircleIcon } from '@heroicons/vue/24/outline';
import { computed, watch, ref } from 'vue';
import Button from './components/Button.vue';
import Input from './components/Input.vue';
import DeckComparison from './components/DeckComparison.vue';
import LoadingIndicator from './components/LoadingIndicator.vue';
import { deckColors } from './lib/deckColors';
import { useDeckComparisonStoreStore } from './store/deckComparisonStore';
import { useDeckStore } from './store/deckStore';
import { useRouter, useRoute } from 'vue-router';
import { encodeDeckURLs, decodeDeckURLs } from './lib/queryStringDeckURLs';
import ErrorDialog from './components/ErrorDialog.vue';
import ManualDeckModal from './components/ManualDeckModal.vue';

const deckStore = useDeckStore();
const comparisonStore = useDeckComparisonStoreStore();

const route = useRoute();
const router = useRouter();
const deckURL = ref('');
const currentLoadingURL = ref('');
const errorDialogOpen = computed(() => {
  return !!deckStore.deckFetchers.get(currentLoadingURL.value)?.error;
});
const manualDeckModalOpen = ref(false);

const queryDeckURLs = computed<string[]>(() => {
  if (route.query.deckURLs) {
    return typeof route.query.deckURLs === 'string'
      ? decodeDeckURLs(route.query.deckURLs)
      : route.query.deckURLs.flatMap((s) => decodeDeckURLs(s ?? ''));
  } else {
    return [];
  }
});

watch(
  queryDeckURLs,
  (urls) => {
    deckStore.updateDecks(urls);
  },
  { immediate: true }
);

watch(deckStore.deckFetchers, () => {
  if (currentLoadingURL.value) {
    const fetcher = deckStore.deckFetchers.get(currentLoadingURL.value);
    if (fetcher?.isFinished && !fetcher?.error) {
      currentLoadingURL.value = '';
    }
  }
});

function handleAdd() {
  const updated = [...queryDeckURLs.value, deckURL.value];
  currentLoadingURL.value = deckURL.value;
  deckURL.value = '';
  router.push({
    query: { deckURLs: encodeDeckURLs(updated) }
  });
}

function removeURL(url: string) {
  const updated = queryDeckURLs.value.filter((q) => q !== url);
  const urlString = updated.length > 0 ? encodeDeckURLs(updated) : '';
  router.push({
    query: { deckURLs: urlString }
  });
}

function handleErrorDialogClose() {
  removeURL(currentLoadingURL.value);
  currentLoadingURL.value = '';
}

function switchToManualAdd() {
  removeURL(currentLoadingURL.value);
  currentLoadingURL.value = '';
  manualDeckModalOpen.value = true;
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
      return [k, (fetcher?.isFetching || !!fetcher?.error) ?? true];
    })
  );
});

function startCompare() {
  comparisonStore.getComparison();
}

const borderColors = computed(() => {
  return {
    orange: 'border-orange-500',
    sky: 'border-sky-500',
    violet: 'border-violet-500',
    pink: 'border-pink-500',
    white: 'border-white'
  };
});
</script>
