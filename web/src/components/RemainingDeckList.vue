<template>
  <div>
    <div class="flex space-x-4">
      <div class="grow">
        <h3 class="text-lg text-white">Main Deck</h3>
        <div class="grid grid-cols-[max-content_1fr_max-content] items-end">
          <template v-for="cardType in cardTypes">
            <template v-if="sortedMainDeck[cardType].length > 0">
              <span
                class="text-background-300 border-background-300 col-span-3 flex items-center border-b py-1 text-base"
              >
                <CardTypeIcon :card-type="cardType" />{{ capitalize(cardType) }}
              </span>
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
import { computed } from 'vue';
import type { DeckSection } from '../types/DeckSection';
import DeckRemainingCardRow from './DeckRemainingCardRow.vue';
import { groupByCardTypes } from '../lib/cardTypeSorter';
import { cardTypes } from '../types/Card';
import { capitalize } from 'lodash-es';
import CardTypeIcon from './CardTypeIcon.vue';

const props = defineProps<{
  deckIndex: number;
  mainDeck: DeckSection | undefined;
  sideboard: DeckSection | undefined;
}>();

const sortedMainDeck = computed(() => groupByCardTypes(props.mainDeck?.cards ?? []));
</script>
