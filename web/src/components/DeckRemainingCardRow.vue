<template>
  <CardRow :card="card">
    <template #quanties>
      <CardQuantity :deck-index="deckIndex" :color="deckColors[deckIndex]" :quantity="quantity" />
    </template>
  </CardRow>
</template>

<script setup lang="ts">
import { deckColors } from '../lib/deckColors';
import type { Card } from '../types/Card';
import CardQuantity from './CardQuantity.vue';
import CardRow from './CardRow.vue';

defineProps<{ card: Card; deckIndex: number; quantity: number | undefined }>();
</script>
