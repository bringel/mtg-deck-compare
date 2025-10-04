<template>
  <div class="even:bg-background-700/50 col-span-3 grid grid-cols-subgrid items-end px-2 py-1">
    <!-- there's some styling that relies on the quantity being an only child to get all the borders right-->
    <CardQuantity :deck-index="deckIndex" :color="deckColors[deckIndex]" :quantity="quantity" />
    <span class="ml-2 text-white">
      {{ card.name }}
    </span>
    <span class="justify-self-end">
      <ManaCost :mana-cost="card.mana_cost" />
      <SetIcon :set="card.set_code" :rarity="card.rarity" class="ml-3 text-[1.5em]" />
    </span>
  </div>
</template>

<script setup lang="ts">
import { deckColors } from '../lib/deckColors';
import type { Card } from '../types/Card';
import CardQuantity from './CardQuantity.vue';
import ManaCost from './ManaCost.vue';
import SetIcon from './SetIcon.vue';

defineProps<{ card: Card; deckIndex: number; quantity: number | undefined }>();
</script>
