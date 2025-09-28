<template>
  <span>
    {{ card.name }}
  </span>

  <span>
    {{ quantities }}
  </span>
</template>

<script setup lang="ts">
import type { Card } from '../types/Card';

const props = defineProps<{ card: Card; quantities: Record<string, number> }>();
</script>
