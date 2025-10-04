<template>
  <div class="even:bg-background-700/50 col-span-3 grid grid-cols-subgrid items-end px-2 py-1">
    <CardQuantities :quantities="quantities" />
    <span class="ml-2 text-white">
      {{ card.name }}
    </span>
    <span class="justify-self-end">
      <ManaCost :mana-cost="card.mana_cost" />
      <SetIcon :set="card.set_code" :rarity="card.rarity" class="ml-3" />
    </span>
  </div>
</template>

<script setup lang="ts">
import type { Card } from '../types/Card';
import CardQuantities from './CardQuantities.vue';
import ManaCost from './ManaCost.vue';
import SetIcon from './SetIcon.vue';

defineProps<{ card: Card; quantities: Record<string, number> | undefined }>();
</script>
