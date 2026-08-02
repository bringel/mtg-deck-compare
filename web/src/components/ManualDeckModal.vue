<template>
  <Dialog :open="open" @close="emit('close')" class="relative z-50">
    <div class="fixed inset-0 bg-black/30" aria-hidden="true" />
    <div class="fixed inset-0 flex w-screen items-center justify-center p-4">
      <DialogPanel class="w-full max-w-lg space-y-4 rounded bg-white px-8 py-4">
        <DialogTitle class="text-xl font-bold">Manually add deck</DialogTitle>
        <Input type="text" id="deck-name" label="Deck name (optional)" v-model="name" />
        <Input type="text" id="deck-author" label="Deck author (optional)" v-model="author" />
        <Input type="url" id="deck-url" label="Deck URL (optional)" v-model="url" />
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
import { ref, computed, watch } from 'vue';
import { Dialog, DialogTitle, DialogPanel } from '@headlessui/vue';
import Input from './Input.vue';
import Button from './Button.vue';
import { useFetch } from '@vueuse/core';
import { type Deck } from '../types/Deck';
import { type ManualCreationResponse } from '../types/ManualCreationResponse';

defineProps<{ open: boolean }>();
const emit = defineEmits<{ close: []; saveSuccessful: [deckID: string, deck: Deck] }>();

const name = ref('');
const author = ref('');
const url = ref('');
const list = ref('');

const data = computed(() => {
  return {
    name: name.value,
    author: author.value,
    url: url.value,
    list: list.value
  };
});

const {
  execute: saveDeck,
  data: deckResponse,
  isFetching
} = useFetch<ManualCreationResponse>('/api/create_manual_deck', { immediate: false }).post(data, 'json').json();

watch(deckResponse, (response) => {
  if (response?.deckId && response?.deck) {
    emit('saveSuccessful', response?.deckId, response?.deck);
  }
});

function cancel() {
  name.value = '';
  author.value = '';
  list.value = '';
  emit('close');
}

function save() {
  saveDeck();
}
</script>
