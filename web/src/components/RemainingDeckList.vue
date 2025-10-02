<template>
  <div class="grid grid-cols-[max-content_1fr_1fr] items-end gap-y-1">
    <DeckRemainingCardRow
      v-for="card in mainDeck?.cards"
      :card="card"
      :quantity="mainDeck?.quantities[card.name]"
      :deck-index="deckIndex"
    />
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
