<template>
  <div class="grid grid-cols-[max-content_1fr_1fr] items-end gap-y-1">
    <ComparisonCardRow
      v-for="card in section?.cards"
      :card="card"
      :quantities="section?.quantities[card.name]"
    />
  </div>
</template>

<script setup lang="ts">
import type { ComparisonDeckSection } from '../types/DeckSection';
import ComparisonCardRow from './ComparisonCardRow.vue';

const props = defineProps<{ section: ComparisonDeckSection | undefined }>();
</script>
