<template>
  <div class="flex space-x-4">
    <div class="flex-grow">
      <h3 class="text-lg text-white">Main Deck</h3>
      <div class="grid grid-cols-[max-content_1fr_max-content] items-end">
        <template v-for="cardType in cardTypes">
          <template v-if="sortedMainDeck[cardType].length > 0">
            <div class="col-span-3 flex items-center py-1 text-base">
              <i :class="['ms', `ms-${cardType}`, 'ms-fw', 'mr-1']"></i>{{ capitalize(cardType) }}
            </div>
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

const props = defineProps<{
  section: { main_deck: ComparisonDeckSection; sideboard: ComparisonDeckSection } | undefined;
}>();

const sortedMainDeck = computed(() => {
  return groupByCardTypes(props.section?.main_deck.cards ?? []);
});

function capitalize(str: String) {
  return `${str.charAt(0).toLocaleUpperCase()}${str.slice(1)}`;
}
</script>
