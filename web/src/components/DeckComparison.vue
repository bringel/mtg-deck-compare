<template>
  <div class="grid grid-cols-2">
    <div>
      <h2>Cards in all decks</h2>
      <div v-if="comparisonStore.comparison?.isFinished">
        <div class="grid grid-cols-[max-content_1fr_1fr] items-center gap-y-1">
          <CardRow
            v-for="card in comparisonStore.comparison?.data?.main_deck.common.cards"
            :card="card"
            :quantities="comparisonStore.comparison?.data?.main_deck.common.quantities[card.name]"
          />
        </div>
      </div>
    </div>
    <div><h2>Cards in multiple decks</h2></div>
    <div class="col-span-2"><h2>Cards in only one deck</h2></div>
  </div>
</template>

<script setup lang="ts">
import { useDeckComparisonStoreStore } from '../store/deckComparisonStore';
import CardRow from './CardRow.vue';

const comparisonStore = useDeckComparisonStoreStore();
</script>
