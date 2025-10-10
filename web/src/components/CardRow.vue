<template>
  <div
    class="nth-of-type-[2n]:bg-background-700/50 group col-span-3 grid cursor-pointer grid-cols-subgrid items-end px-2 py-1"
    ref="anchor"
  >
    <slot name="quanties"></slot>
    <span class="ml-2 text-white">
      {{ card.name }}
    </span>
    <span class="justify-self-end">
      <ManaCost :mana-cost="card.mana_cost" />
      <SetIcon :set="card.set_code" :rarity="card.rarity" class="ml-2" />
    </span>
    <FloatingCardImage ref="floating" :card="card" :style="floatingStyles" />
  </div>
</template>

<script setup lang="ts">
import { useTemplateRef, type Ref, type ComponentPublicInstance } from 'vue';
import type { Card } from '../types/Card';
import ManaCost from './ManaCost.vue';
import SetIcon from './SetIcon.vue';
import FloatingCardImage from './FloatingCardImage.vue';
import {
  useFloating,
  autoUpdate,
  type UseFloatingReturn,
  autoPlacement,
  shift
} from '@floating-ui/vue';

defineProps<{ card: Card }>();

const anchor: Ref<HTMLElement | null> = useTemplateRef('anchor');
const cardImageRef: Ref<ComponentPublicInstance | null> = useTemplateRef('floating');

const { floatingStyles }: UseFloatingReturn = useFloating(anchor, cardImageRef, {
  whileElementsMounted: autoUpdate,
  middleware: [autoPlacement(), shift()]
});
</script>
