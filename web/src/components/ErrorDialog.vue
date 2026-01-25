<template>
  <Dialog :open="isOpen" @close="isOpen = false" class="relative z-50">
    <div class="fixed inset-0 flex w-screen justify-center p-4">
      <DialogPanel class="max-h-[fit-content] w-full max-w-sm flex-1 rounded bg-red-200 px-6 pt-3 pb-6">
        <DialogTitle class="text-xl text-red-900">Error loading deck list</DialogTitle>

        <div class="my-3 text-red-900">
          Sorry! We're having some trouble loading the deck from the URL you entered. While we work on fixing it, you
          can enter the deck list manually, or try again in a little bit
        </div>

        <div class="flex justify-end space-x-2">
          <Button theme="error">Enter manually</Button>
          <Button theme="error">Close</Button>
        </div>
      </DialogPanel>
    </div>
  </Dialog>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/vue';
import Button from './Button.vue';

const isOpen = ref(true);
</script>
