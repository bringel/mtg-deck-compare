<template>
  <div class="flex space-x-4">
    <div class="grow">
      <h3 class="text-lg text-white">Main Deck</h3>
      <div class="grid grid-cols-[max-content_1fr_max-content] items-end gap-y-3">
        <ComparisonCardRow
          v-for="card in section?.main_deck.cards"
          :card="card"
          :quantities="section?.main_deck.quantities[card.name]"
        />
      </div>
    </div>
    <div class="grow">
      <h3 class="text-lg text-white">Sidboard</h3>
      <div class="grid grid-cols-[max-content_1fr_max-content] items-end gap-y-3">
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
import type { ComparisonDeckSection } from 'src/types/ComparisonDeckSection';
import ComparisonCardRow from './ComparisonCardRow.vue';

defineProps<{
  section: { main_deck: ComparisonDeckSection; sideboard: ComparisonDeckSection } | undefined;
}>();
</script>
