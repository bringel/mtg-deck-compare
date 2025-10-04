<template>
  <div class="grid grid-cols-2 gap-6">
    <Card v-if="showAllSection">
      <template #header><h2 class="text-2xl text-white">Cards in all decks</h2></template>
      <ComparisonSection :section="comparisonData?.common" />
    </Card>
    <Card v-if="showMultipleSection">
      <template #header><h2 class="text-2xl text-white">Cards in multiple decks</h2></template>
      <ComparisonSection :section="comparisonData?.multiple" />
    </Card>
    <template v-if="showRemainingSection">
      <Card v-for="(remaining, index) in comparisonData?.decks_remaining">
        <template #header>
          <h2 class="text-2xl text-white">Deck {{ Number(index) + 1 }} Remaining Cards</h2>
        </template>
        <RemainingDeckList
          :deck-index="index"
          :main-deck="remaining.main_deck"
          :sideboard="remaining.sideboard"
        />
      </Card>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useDeckComparisonStoreStore } from '../store/deckComparisonStore';
import ComparisonSection from './ComparisonSection.vue';
import RemainingDeckList from './RemainingDeckList.vue';
import Card from './Card.vue';

const comparisonStore = useDeckComparisonStoreStore();

const comparisonData = computed(() => comparisonStore.comparison?.data);

const showAllSection = computed(() => {
  if (!comparisonData.value) {
    return false;
  }

  return (
    comparisonData.value.common.main_deck.cards.length ||
    comparisonData.value.common.sideboard.cards.length
  );
});

const showMultipleSection = computed(() => {
  return (
    comparisonData.value?.multiple.main_deck.cards.length ||
    comparisonData.value?.multiple.sideboard.cards.length
  );
});

const showRemainingSection = computed(() => {
  if (!comparisonData.value) {
    return false;
  }

  return Object.keys(comparisonData.value.decks_remaining).length > 0;
});
</script>
