<template>
  <div class="flex">
    <div>
      <h3 class="text-white text-lg">Main Deck</h3>
      <div class="grid grid-cols-[max-content_1fr_1fr] items-end gap-y-1">
        <ComparisonCardRow
          v-for="card in section?.main_deck.cards"
          :card="card"
          :quantities="section?.main_deck.quantities[card.name]"
        />
      </div>
    </div>
    <div>
      <h3 class="text-white text-lg">Sidboard</h3>
      <div class="grid grid-cols-[max-content_1fr_1fr] items-end gap-y-1">
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
