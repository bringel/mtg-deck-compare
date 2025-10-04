<template>
  <div class="border-background-300 rounded-md border-2 px-8 pt-2 pb-8">
    <div class="mb-3">
      <slot name="header"></slot>
    </div>
    <slot></slot>
  </div>
</template>

<script setup lang="ts"></script>
