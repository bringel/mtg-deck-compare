<template>
  <div class="grid grid-cols-2">
    <div>
      <h2 class="text-white text-2xl">Cards in all decks</h2>
      <div v-if="comparisonStore.comparison?.isFinished" class="flex">
        <div>
          <h3 class="text-white text-lg">Main Deck</h3>
          <ComparisonSection :section="comparisonStore.comparison?.data?.main_deck.common" />
        </div>
        <div>
          <h3 class="text-white text-lg">Sideboard</h3>
          <ComparisonSection :section="comparisonStore.comparison?.data?.sideboard.common" />
        </div>
      </div>
    </div>
    <template v-if="showMultipleSection">
      <div>
        <h2 class="text-white text-2xl">Cards in multiple decks</h2>
        <div>
          <h3 class="text-white text-lg">Main Deck</h3>
          <ComparisonSection :section="comparisonStore.comparison?.data?.main_deck.multiple" />
        </div>
        <div>
          <h3 class="text-white text-lg">Sideboard</h3>
          <ComparisonSection :section="comparisonStore.comparison?.data?.sideboard.multiple" />
        </div>
      </div>
    </template>
    <div class="col-span-2">
      <h2 class="text-white text-2xl">Cards in only one deck</h2>
      <div class="flex">
        <RemainingDeckList
          v-for="(remaining, index) in remainingDecks"
          :deck-index="index"
          :main-deck="remaining.mainDeck"
          :sideboard="remaining.sideboard"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useDeckComparisonStoreStore } from '../store/deckComparisonStore';
import ComparisonSection from './ComparisonSection.vue';
import RemainingDeckList from './RemainingDeckList.vue';
import { useDeckStore } from '../store/deckStore';

const comparisonStore = useDeckComparisonStoreStore();

const deckStore = useDeckStore();
const showMultipleSection = computed(() => {
  const comparisonData = comparisonStore.comparison?.data;

  return (
    comparisonData?.main_deck.multiple.cards.length ||
    comparisonData?.sideboard.multiple.cards.length
  );
});

const remainingDecks = computed(() => {
  const remainingMainDecks = comparisonStore.comparison?.data?.main_deck.decks_remaining;
  const remainingSideboards = comparisonStore.comparison?.data?.sideboard.decks_remaining;
  return deckStore.deckURLs.map((deck, index) => {
    return {
      mainDeck: remainingMainDecks?.[index],
      sideboard: remainingSideboards?.[index]
    };
  });
});
</script>
