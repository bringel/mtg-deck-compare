<template>
  <Dialog :open="isOpen" @close="emit('close')" class="relative z-50">
    <div class="fixed inset-0 flex w-screen justify-center p-4">
      <DialogPanel class="max-h-[fit-content] w-full max-w-sm flex-1 rounded bg-red-200 px-6 pt-3 pb-6">
        <DialogTitle class="text-xl text-red-900">
          <slot name="title"></slot>
        </DialogTitle>
        <div class="my-3 text-red-900">
          <slot name="body"></slot>
        </div>
        <div class="flex justify-end space-x-2">
          <slot name="buttons"></slot>
        </div>
      </DialogPanel>
    </div>
  </Dialog>
</template>

<script setup lang="ts">
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/vue';

const props = defineProps<{
  isOpen: boolean;
}>();

const emit = defineEmits<{
  close: [];
}>();
</script>
