<template>
  <div class="flex flex-col">
    <label :for="id" :class="['dark:text-white', { 'sr-only': props.hideLabel }]">{{ label }}</label>
    <input :id="id" :class="['rounded-sm', props.class]" v-model="model" v-bind="$attrs" />
  </div>
</template>

<script setup lang="ts">
defineOptions({ inheritAttrs: false });
const props = withDefaults(
  defineProps<{
    id?: string;
    label?: string;
    hideLabel?: boolean;
    class?: string;
  }>(),
  { hideLabel: false, id: '', class: '', label: '' }
);

const model = defineModel<string>();
</script>
