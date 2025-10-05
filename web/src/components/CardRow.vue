<template>
  <div
    class="nth-of-type-[2n]:bg-background-700/50 col-span-3 grid grid-cols-subgrid items-end px-2 py-1"
  >
    <slot name="quanties"></slot>
    <span class="ml-2 text-white">
      {{ card.name }}
    </span>
    <span class="justify-self-end">
      <ManaCost :mana-cost="card.mana_cost" />
      <SetIcon :set="card.set_code" :rarity="card.rarity" class="ml-2" />
    </span>
  </div>
</template>

<script setup lang="ts">
import type { Card } from '../types/Card';
import ManaCost from './ManaCost.vue';
import SetIcon from './SetIcon.vue';

defineProps<{ card: Card }>();
</script>
