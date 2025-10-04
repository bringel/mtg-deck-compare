<template>
  <div class="border-2 rounded-md border-background-300 pt-2 pb-8 px-8">
    <div class="mb-3">
      <slot name="header"></slot>
    </div>
    <slot></slot>
  </div>
</template>

<script setup lang="ts"></script>
