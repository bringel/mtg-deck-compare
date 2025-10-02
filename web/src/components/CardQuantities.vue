<template>
  <div class="flex">
    <CardQuantity
      v-for="(quantity, deck) in quantities"
      :deck-index="Number(deck)"
      :color="deckColors[Number(deck)]"
      :quantity="quantity"
    />
  </div>
</template>

<script setup lang="ts">
import CardQuantity from './CardQuantity.vue';
import { deckColors } from '../lib/deckColors';

defineProps<{ quantities: Record<string, number> | undefined }>();
</script>
