<template>
  <div>
    <CardQuantity
      v-for="(quantity, deck) in quantities"
      :deck-index="Number(deck)"
      :color="colors[Number(deck)]"
      :quantity="quantity"
    />
  </div>
</template>

<script setup lang="ts">
import CardQuantity from './CardQuantity.vue';

const props = defineProps<{ quantities: Record<string, number> | undefined }>();
const colors = ['orange', 'cyan', 'violet', 'pink'];
</script>
