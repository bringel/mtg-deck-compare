<template>
  <div class="grid grid-cols-2">
    <div>
      <h2>Cards in all decks</h2>
      <div v-if="comparisonStore.comparison?.isFinished">
        <ul>
          <li
            class="list-none flex flex-row justify-between"
            v-for="card in comparisonStore.comparison?.data.main_deck.common.cards"
          >
            <CardRow
              :card="card"
              :quantities="comparisonStore.comparison?.data.main_deck.common.quantities[card.name]"
            />
          </li>
        </ul>
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
