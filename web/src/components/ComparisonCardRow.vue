<template>
  <CardRow :card="card">
    <template #quanties>
      <CardQuantities :quantities="quantities" />
    </template>
  </CardRow>
</template>

<script setup lang="ts">
import type { Card } from '../types/Card';
import CardRow from './CardRow.vue';
import CardQuantities from './CardQuantities.vue';

defineProps<{ card: Card; quantities: Record<string, number> | undefined }>();
</script>
