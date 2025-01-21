<template>
  <AppShell>
    <div class="space-y-2 flex flex-col">
      <AddDeckURLInput
        v-for="(url, index) in deckURLs"
        :key="index"
        :model-value="url"
        :removable="index >= 2"
        @update:model-value="($event: string) => updateURL(index, $event)"
        @remove="handleRemove(index)"
      />
    </div>
    <div class="flex flex-row space-x-4 mt-4">
      <Button @click="handleAdd">Add</Button>
      <Button @click="startCompare">Compare</Button>
    </div>
  </AppShell>
</template>

<script setup lang="ts">
import AddDeckURLInput from './components/AddDeckURLInput.vue';
import AppShell from './components/AppShell.vue';
import { ref } from 'vue';
import Button from './components/Button.vue';

const deckURLs = ref(['', '']);

function updateURL(index: number, value: string) {
  deckURLs.value.splice(index, 1, value);
}

function handleRemove(index: number) {
  deckURLs.value.splice(index, 1);
}

function handleAdd() {
  deckURLs.value.push('');
}

function startCompare() {}
</script>
