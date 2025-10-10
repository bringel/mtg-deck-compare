<template>
  <figure :class="['z-10', 'hidden', 'group-hover:flex', 'gap-1']">
    <div
      v-for="(imageURL, index) in card.card_image_urls"
      :class="{
        'flex h-[535px] w-[535px] items-center justify-center': frontRotated && index === 0
      }"
    >
      <img
        :src="imageURL"
        :class="[
          'w-96',
          'h-[535px]',
          'rounded-[4.75%_/_3.5%]',
          'shadow-md',
          'shadow-black',
          { 'rotate-90': frontRotated && index === 0 }
        ]"
      />
    </div>
  </figure>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { Card } from '../types/Card';

const props = defineProps<{ card: Card }>();

const frontRotated = computed(() => {
  return props.card.layout === 'battle' || props.card.layout === 'split';
});

const canRotate = computed(() => {
  return props.card.layout === 'flip';
});

const canRotateNinety = computed(() => {
  return props.card.layout === 'aftermath';
});
</script>
