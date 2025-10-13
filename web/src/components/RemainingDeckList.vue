<template>
  <div>
    <div class="xl:flex xl:space-x-4">
      <div class="md:grow">
        <h3 class="text-lg dark:text-white">Main Deck</h3>
        <div class="md:grid md:grid-cols-[max-content_1fr_max-content] md:items-end">
          <template v-for="cardType in cardTypes">
            <template v-if="sortedMainDeck[cardType].length > 0">
              <CardTypeHeader :card-type="cardType" />
              <DeckRemainingCardRow
                v-for="card in sortedMainDeck[cardType]"
                :card="card"
                :quantity="mainDeck?.quantities[card.name]"
                :deck-index="Number(deckIndex)"
              />
            </template>
          </template>
        </div>
      </div>
      <div class="md:grow">
        <h3 class="text-lg dark:text-white">Sideboard</h3>
        <div class="mid:items-end md:grid md:grid-cols-[max-content_1fr_max-content]">
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
import { computed } from 'vue';
import type { DeckSection } from '../types/DeckSection';
import DeckRemainingCardRow from './DeckRemainingCardRow.vue';
import { groupByCardTypes } from '../lib/cardTypeSorter';
import { cardTypes } from '../types/Card';
import CardTypeHeader from './CardTypeHeader.vue';

const props = defineProps<{
  deckIndex: number;
  mainDeck: DeckSection | undefined;
  sideboard: DeckSection | undefined;
}>();

const sortedMainDeck = computed(() => groupByCardTypes(props.mainDeck?.cards ?? []));
</script>
