<template>
  <div class="bg-background-600 shadow-background-400/50 rounded-md px-8 pt-2 pb-8 shadow-sm">
    <div class="mb-3">
      <slot name="header"></slot>
    </div>
    <slot></slot>
  </div>
</template>

<script setup lang="ts"></script>
