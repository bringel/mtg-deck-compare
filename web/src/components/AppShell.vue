<template>
  <div class="min-h-screen bg-background-700">
    <HeaderBar />
    <div class="py-4 px-8">
      <slot></slot>
    </div>
  </div>
</template>

<script setup lang="ts">
import HeaderBar from './HeaderBar.vue';
</script>

<style scoped></style>
