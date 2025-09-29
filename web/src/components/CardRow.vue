<template>
  <span>
    {{ card.name }}
  </span>
  <CardQuantities :quantities="quantities" />
</template>

<script setup lang="ts">
import type { Card } from '../types/Card';
import CardQuantities from './CardQuantities.vue';

defineProps<{ card: Card; quantities: Record<string, number> | undefined }>();
</script>
