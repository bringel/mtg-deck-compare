<template>
  <div class="bg-background-700 min-h-screen">
    <HeaderBar />
    <div class="px-8 py-4">
      <slot></slot>
    </div>
  </div>
</template>

<script setup lang="ts">
import HeaderBar from './HeaderBar.vue';
</script>

<style scoped></style>
