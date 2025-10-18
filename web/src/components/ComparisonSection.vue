<template>
  <div class="xl:flex xl:space-x-4">
    <div class="md:flex-grow">
      <h3 class="text-lg dark:text-white">Main Deck</h3>
      <div class="flex flex-col md:grid md:grid-cols-[max-content_1fr_max-content] md:items-end">
        <template v-for="cardType in cardTypes">
          <template v-if="sortedMainDeck[cardType].length > 0">
            <CardTypeHeader :card-type="cardType" />
            <ComparisonCardRow
              v-for="card in sortedMainDeck[cardType]"
              :card="card"
              :quantities="section?.mainDeck.quantities[card.name]"
            />
          </template>
        </template>
      </div>
    </div>
    <div class="md:flex-grow">
      <h3 class="text-lg dark:text-white">Sideboard</h3>
      <div class="flex flex-col md:grid md:grid-cols-[max-content_1fr_max-content] md:items-end">
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
import CardTypeHeader from './CardTypeHeader.vue';

const props = defineProps<{
  section: { mainDeck: ComparisonDeckSection; sideboard: ComparisonDeckSection } | undefined;
}>();

const sortedMainDeck = computed(() => {
  return groupByCardTypes(props.section?.mainDeck.cards ?? []);
});
</script>
