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
          <Button theme="primary" :disabled="!list" @click="save" :loading="isFetching">Save</Button>
        </div>
      </DialogPanel>
    </div>
  </Dialog>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { Dialog, DialogTitle, DialogPanel } from '@headlessui/vue';
import Input from './Input.vue';
import Button from './Button.vue';
import { useFetch } from '@vueuse/core';

defineProps<{ open: boolean }>();
const emit = defineEmits<{ close: [] }>();

const name = ref('');
const author = ref('');
const list = ref('');

const data = computed(() => {
  return {
    name: name.value,
    author: author.value,
    list: list.value
  };
});

const {
  execute: saveDeck,
  data: deckResponse,
  isFetching
} = useFetch('/api/create_manual_deck', { immediate: false }).post(data, 'json');

function cancel() {
  name.value = '';
  author.value = '';
  list.value = '';
  emit('close');
}

function save() {
  saveDeck();
  emit('close');
}
</script>
