<template>
  <figure class="z-10 hidden group-hover:flex">
    <img
      v-for="imageURL in cardImageUrls"
      :src="imageURL"
      class="w-96 rounded-[4.75%_/_3.5%] shadow-md shadow-black"
    />
  </figure>
</template>

<script setup lang="ts">
const props = defineProps<{ cardImageUrls: Array<string> }>();
</script>
