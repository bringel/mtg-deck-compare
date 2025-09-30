<template>
  <div class="grid grid-cols-[max-content_1fr_1fr] items-end gap-y-1">
    <CardRow
      v-for="card in section?.cards"
      :card="card"
      :quantities="section?.quantities[card.name]"
    />
  </div>
</template>

<script setup lang="ts">
import type { DeckSection } from '../types/DeckSection';
import CardRow from './CardRow.vue';

const props = defineProps<{ section: DeckSection | undefined }>();
</script>
