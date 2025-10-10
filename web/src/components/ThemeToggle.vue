<template>
  <RadioGroup v-model="themeChoice" class="bg-background-300 relative flex gap-1 rounded-md">
    <div
      :class="[
        'absolute size-10 rounded-md bg-white/95 transition-transform duration-75',
        { 'translate-x-11': themeChoice === 'system', 'translate-x-22': themeChoice === 'dark' }
      ]"
    ></div>
    <RadioGroupOption v-for="theme in themeOptions" :value="theme" class="z-10 cursor-pointer">
      <SunIcon v-if="theme == 'light'" :class="iconClasses" />
      <ComputerDesktopIcon v-if="theme == 'system'" :class="iconClasses" />
      <MoonIcon v-if="theme == 'dark'" :class="iconClasses" />
    </RadioGroupOption>
  </RadioGroup>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { RadioGroup, RadioGroupLabel, RadioGroupOption } from '@headlessui/vue';

import { MoonIcon, SunIcon, ComputerDesktopIcon } from '@heroicons/vue/24/outline';

const themeOptions = ['light', 'system', 'dark'] as const;
type Theme = (typeof themeOptions)[number];
const themeChoice = ref<Theme>('system');

const iconClasses = ref(['size-10', 'p-2', 'rounded-md']);
</script>
