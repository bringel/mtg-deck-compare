import { createRouter, createWebHistory } from 'vue-router';
import Compare from '../Compare.vue';

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/compare',
      name: 'compare',
      component: Compare
    }
  ]
});

export default router;
