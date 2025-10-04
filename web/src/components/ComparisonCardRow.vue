<template>
  <CardQuantities :quantities="quantities" />
  <span class="ml-2 text-white">
    {{ card.name }}
  </span>
  <span class="justify-self-end">
    <ManaCost :mana-cost="card.mana_cost" />
    <SetIcon :set="card.set_code" :rarity="card.rarity" class="ml-3 text-[1.5em]" />
  </span>
</template>

<script setup lang="ts">
import type { Card } from '../types/Card';
import CardQuantities from './CardQuantities.vue';
import ManaCost from './ManaCost.vue';
import SetIcon from './SetIcon.vue';

defineProps<{ card: Card; quantities: Record<string, number> | undefined }>();
</script>
