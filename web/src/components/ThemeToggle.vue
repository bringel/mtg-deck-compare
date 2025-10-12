<template>
  <RadioGroup v-model="theme" class="bg-background-300 relative flex gap-1 rounded-md">
    <div
      :class="[
        'absolute size-10 rounded-md bg-white/95 transition-transform duration-75',
        { 'translate-x-11': theme === 'auto', 'translate-x-22': theme === 'dark' }
      ]"
    ></div>
    <RadioGroupOption v-for="theme in themeOptions" :value="theme" class="z-10 cursor-pointer">
      <SunIcon v-if="theme == 'light'" :class="iconClasses" />
      <ComputerDesktopIcon v-if="theme == 'auto'" :class="iconClasses" />
      <MoonIcon v-if="theme == 'dark'" :class="iconClasses" />
    </RadioGroupOption>
  </RadioGroup>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { RadioGroup, RadioGroupLabel, RadioGroupOption } from '@headlessui/vue';
import { MoonIcon, SunIcon, ComputerDesktopIcon } from '@heroicons/vue/24/outline';
import { useTheme, themeOptions } from '../composables/useTheme';

const iconClasses = ref(['size-10', 'p-2', 'rounded-md']);

const theme = useTheme();
</script>
