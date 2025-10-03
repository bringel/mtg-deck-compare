<template>
  <div class="grid grid-cols-2">
    <div>
      <h2 class="text-white text-2xl">Cards in all decks</h2>
      <ComparisonSection :section="comparisonStore.comparison?.data?.common" />
    </div>
    <template v-if="showMultipleSection">
      <div>
        <h2 class="text-white text-2xl">Cards in multiple decks</h2>
        <ComparisonSection :section="comparisonStore.comparison?.data?.multiple" />
      </div>
    </template>
    <div class="col-span-2">
      <h2 class="text-white text-2xl">Cards in only one deck</h2>
      <div class="flex">
        <RemainingDeckList
          v-for="(remaining, index) in comparisonStore.comparison?.data?.decks_remaining"
          :deck-index="index"
          :main-deck="remaining.main_deck"
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

const comparisonStore = useDeckComparisonStoreStore();

const showMultipleSection = computed(() => {
  const comparisonData = comparisonStore.comparison?.data;

  return (
    comparisonData?.multiple.main_deck.cards.length ||
    comparisonData?.multiple.sideboard.cards.length
  );
});
</script>
