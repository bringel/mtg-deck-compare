<template>
  <AppShell>
    <div>
      <AddDeckURLInput
        v-for="(url, index) in deckURLs"
        :key="index"
        :model-value="url"
        @update:model-value="($event:string) => updateURL(index, $event)"
        @remove="handleRemove(index)"
      />
    </div>
  </AppShell>
</template>

<script setup lang="ts">
import AddDeckURLInput from './components/AddDeckURLInput.vue';
import AppShell from './components/AppShell.vue';
import { ref } from 'vue';

const deckURLs = ref(['', '']);

function updateURL(index: number, value: string) {
  deckURLs.value.splice(index, 1, value);
}

function handleRemove(index: number) {
  deckURLs.value.splice(index, 1);
  //test
}
</script>
