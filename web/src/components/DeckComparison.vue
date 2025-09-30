<template>
  <div class="grid grid-cols-2">
    <div>
      <h2>Cards in all decks</h2>
      <div v-if="comparisonStore.comparison?.isFinished">
        <ComparisonSection :section="comparisonStore.comparison?.data?.main_deck.common" />
        <ComparisonSection :section="comparisonStore.comparison?.data?.sideboard.common" />
      </div>
    </div>
    <template v-if="showMultipleSection">
      <div><h2>Cards in multiple decks</h2></div>
      <ComparisonSection :section="comparisonStore.comparison?.data?.main_deck.multiple" />
      <ComparisonSection :section="comparisonStore.comparison?.data?.sideboard.multiple" />
    </template>
    <div class="col-span-2"><h2>Cards in only one deck</h2></div>
    <ComparisonSection
      v-for="remaining in comparisonStore.comparison?.data?.main_deck.decks_remaining"
      :section="remaining"
    />
    <ComparisonSection
      v-for="remaining in comparisonStore.comparison?.data?.sideboard.decks_remaining"
      :section="remaining"
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useDeckComparisonStoreStore } from '../store/deckComparisonStore';
import ComparisonSection from './ComparisonSection.vue';

const comparisonStore = useDeckComparisonStoreStore();

const showMultipleSection = computed(() => {
  const comparisonData = comparisonStore.comparison?.data;

  return (
    comparisonData?.main_deck.multiple.cards.length ||
    comparisonData?.sideboard.multiple.cards.length
  );
});
</script>
