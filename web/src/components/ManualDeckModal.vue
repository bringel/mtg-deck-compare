<template>
  <Dialog :open="open" @close="emit('close')" class="relative z-50">
    <div class="fixed inset-0 bg-black/30" aria-hidden="true" />
    <div class="fixed inset-0 flex w-screen items-center justify-center p-4">
      <DialogPanel class="w-full max-w-lg space-y-4 rounded bg-white px-8 py-4">
        <DialogTitle class="text-xl font-bold">Manually add deck</DialogTitle>
        <Input type="text" id="deck-name" label="Deck name (optional)" v-model="name" />
        <Input type="text" id="deck-author" label="Deck author (optional)" v-model="author" />
        <label for="deck-list">List</label>
        <textarea id="deck-list" v-model="list" class="w-full rounded-sm" rows="15"></textarea>
        <div class="flex justify-end space-x-2">
          <Button theme="secondary" @click="cancel">Cancel</Button>
          <Button theme="primary" :disabled="!list">Save</Button>
        </div>
      </DialogPanel>
    </div>
  </Dialog>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { Dialog, DialogTitle, DialogPanel } from '@headlessui/vue';
import Input from './Input.vue';
import Button from './Button.vue';

defineProps<{ open: boolean }>();
const emit = defineEmits<{ close: [] }>();

const name = ref('');
const author = ref('');
const list = ref('');

function cancel() {
  name.value = '';
  author.value = '';
  list.value = '';
  emit('close');
}
</script>
