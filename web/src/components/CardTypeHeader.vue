<template>
  <span
    class="dark:text-background-300 dark:border-background-300 flex items-center border-b py-1 text-base not-dark:border-y md:col-span-3"
  >
    <CardTypeIcon :card-type="cardType" />{{ capitalize(cardType) }}
  </span>
</template>

<script setup lang="ts">
import { capitalize } from 'lodash-es';
import type { CardType } from '../types/Card';
import CardTypeIcon from './CardTypeIcon.vue';

defineProps<{ cardType: CardType }>();
</script>
