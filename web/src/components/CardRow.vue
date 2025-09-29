<template>
  <CardQuantities :quantities="quantities" />
  <span class="ml-2 text-white">
    {{ card.name }}
  </span>
  <ManaCost :mana-cost="card.mana_cost" />
</template>

<script setup lang="ts">
import type { Card } from '../types/Card';
import CardQuantities from './CardQuantities.vue';
import ManaCost from './ManaCost.vue';

defineProps<{ card: Card; quantities: Record<string, number> | undefined }>();
</script>
