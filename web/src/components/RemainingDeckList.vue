<template>
  <div>
    <h3 class="text-white text-lg">Deck {{ deckIndex + 1 }}</h3>
    <div class="flex">
      <div>
        <h3 class="text-white text-lg">Main Deck</h3>
        <div class="grid grid-cols-[max-content_1fr_1fr] items-end gap-y-1">
          <DeckRemainingCardRow
            v-for="card in mainDeck?.cards"
            :card="card"
            :quantity="mainDeck?.quantities[card.name]"
            :deck-index="deckIndex"
          />
        </div>
      </div>
      <div>
        <h3 class="text-white text-lg">Sideboard</h3>
        <div class="grid grid-cols-[max-content_1fr_1fr] items-end gap-y-1">
          <DeckRemainingCardRow
            v-for="card in sideboard?.cards"
            :card="card"
            :quantity="sideboard?.quantities[card.name]"
            :deck-index="deckIndex"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { RemainingDeckSection } from '../types/DeckSection';
import DeckRemainingCardRow from './DeckRemainingCardRow.vue';

defineProps<{
  deckIndex: number;
  mainDeck: RemainingDeckSection | undefined;
  sideboard: RemainingDeckSection | undefined;
}>();
</script>
