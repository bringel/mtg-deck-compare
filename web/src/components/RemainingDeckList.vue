<template>
  <div>
    <div class="flex space-x-4">
      <div class="grow">
        <h3 class="text-lg text-white">Main Deck</h3>
        <div class="grid grid-cols-[max-content_1fr_max-content] items-end">
          <DeckRemainingCardRow
            v-for="card in mainDeck?.cards"
            :card="card"
            :quantity="mainDeck?.quantities[card.name]"
            :deck-index="Number(deckIndex)"
          />
        </div>
      </div>
      <div class="grow">
        <h3 class="text-lg text-white">Sideboard</h3>
        <div class="grid grid-cols-[max-content_1fr_max-content] items-end">
          <DeckRemainingCardRow
            v-for="card in sideboard?.cards"
            :card="card"
            :quantity="sideboard?.quantities[card.name]"
            :deck-index="Number(deckIndex)"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { DeckSection } from '../types/DeckSection';
import DeckRemainingCardRow from './DeckRemainingCardRow.vue';

defineProps<{
  deckIndex: number;
  mainDeck: DeckSection | undefined;
  sideboard: DeckSection | undefined;
}>();
</script>
