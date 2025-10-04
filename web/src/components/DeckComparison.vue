<template>
  <div class="grid grid-cols-2 gap-6">
    <Card>
      <template #header><h2 class="text-2xl text-white">Cards in all decks</h2></template>
      <ComparisonSection :section="comparisonStore.comparison?.data?.common" />
    </Card>
    <Card v-if="showMultipleSection">
      <template #header><h2 class="text-2xl text-white">Cards in multiple decks</h2></template>
      <ComparisonSection :section="comparisonStore.comparison?.data?.multiple" />
    </Card>
    <Card v-for="(remaining, index) in comparisonStore.comparison?.data?.decks_remaining">
      <template #header>
        <h2 class="text-2xl text-white">Deck {{ Number(index) + 1 }} Remaining Cards</h2>
      </template>
      <RemainingDeckList
        :deck-index="index"
        :main-deck="remaining.main_deck"
        :sideboard="remaining.sideboard"
      />
    </Card>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useDeckComparisonStoreStore } from '../store/deckComparisonStore';
import ComparisonSection from './ComparisonSection.vue';
import RemainingDeckList from './RemainingDeckList.vue';
import Card from './Card.vue';

const comparisonStore = useDeckComparisonStoreStore();

const showMultipleSection = computed(() => {
  const comparisonData = comparisonStore.comparison?.data;

  return (
    comparisonData?.multiple.main_deck.cards.length ||
    comparisonData?.multiple.sideboard.cards.length
  );
});
</script>
