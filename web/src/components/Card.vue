<template>
  <div
    class="bg-background-50 shadow-background-700/50 dark:bg-background-600 dark:shadow-background-400/50 rounded-md px-8 py-4 pb-8 shadow-md dark:shadow-sm"
  >
    <div class="mb-3">
      <slot name="header"></slot>
    </div>
    <slot></slot>
  </div>
</template>

<script setup lang="ts"></script>
