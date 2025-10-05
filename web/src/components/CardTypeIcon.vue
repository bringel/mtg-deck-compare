<template>
  <i :class="['ms', `ms-${cardType}`, 'ms-fw', 'mr-1']"></i>
</template>

<script setup lang="ts">
import { type CardType } from '../types/Card';

defineProps<{ cardType: CardType }>();
</script>
