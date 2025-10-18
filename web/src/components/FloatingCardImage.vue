<template>
  <figure class="z-10 hidden flex-col gap-2 group-hover:flex">
    <div class="flex flex-row gap-1">
      <div
        v-for="(imageURL, index) in card.cardImageUrls"
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
            'transition-transform',
            { 'rotate-90': frontRotated && index === 0 },
            { 'rotate-180': flipped },
            { 'rotate-[-90deg]': manuallyRotated }
          ]"
        />
      </div>
    </div>
    <Button v-if="canFlip" theme="secondary" @click="flipCard">
      <span class="align-center flex justify-center">
        <ArrowPathIcon class="mr-2 size-6" />
        Flip
      </span>
    </Button>
    <Button v-else-if="canRotateNinety" theme="secondary" @click="rotate">
      <span class="align-center flex justify-center">
        <ArrowUturnRightIcon v-if="manuallyRotated" class="mr-2 size-6" />
        <ArrowUturnLeftIcon v-else class="mr-2 size-6" />
        Rotate
      </span>
    </Button>
  </figure>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';
import type { Card } from '../types/Card';
import Button from './Button.vue';
import { ArrowPathIcon, ArrowUturnLeftIcon, ArrowUturnRightIcon } from '@heroicons/vue/24/outline';

const props = defineProps<{ card: Card }>();
const flipped = ref(false);
const manuallyRotated = ref(false);

const frontRotated = computed(() => {
  return props.card.layout === 'battle' || props.card.layout === 'split';
});

const canFlip = computed(() => {
  return props.card.layout === 'flip';
});

const canRotateNinety = computed(() => {
  return props.card.layout === 'aftermath';
});

function flipCard() {
  flipped.value = !flipped.value;
}

function rotate() {
  manuallyRotated.value = !manuallyRotated.value;
}
</script>
