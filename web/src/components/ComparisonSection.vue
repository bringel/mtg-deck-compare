<template>
  <div class="flex space-x-4">
    <div class="flex-grow">
      <h3 class="text-lg text-white">Main Deck</h3>
      <div class="grid grid-cols-[max-content_1fr_max-content] items-end">
        <template v-for="cardType in cardTypes">
          <template v-if="sortedMainDeck[cardType].length > 0">
            <span class="text-background-300 col-span-3 flex items-center py-1 text-base">
              <CardTypeIcon :card-type="cardType" />{{ capitalize(cardType) }}
            </span>
            <ComparisonCardRow
              v-for="card in sortedMainDeck[cardType]"
              :card="card"
              :quantities="section?.main_deck.quantities[card.name]"
            />
          </template>
        </template>
      </div>
    </div>
    <div class="flex-grow">
      <h3 class="text-lg text-white">Sideboard</h3>
      <div class="grid grid-cols-[max-content_1fr_max-content] items-end">
        <ComparisonCardRow
          v-for="card in section?.sideboard.cards"
          :card="card"
          :quantities="section?.sideboard.quantities[card.name]"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { ComparisonDeckSection } from '../types/ComparisonDeckSection';
import ComparisonCardRow from './ComparisonCardRow.vue';
import { groupByCardTypes } from '../lib/cardTypeSorter';
import { computed } from 'vue';
import { cardTypes } from '../types/Card';
import { capitalize } from 'lodash-es';
import CardTypeIcon from './CardTypeIcon.vue';

const props = defineProps<{
  section: { main_deck: ComparisonDeckSection; sideboard: ComparisonDeckSection } | undefined;
}>();

const sortedMainDeck = computed(() => {
  return groupByCardTypes(props.section?.main_deck.cards ?? []);
});
</script>
