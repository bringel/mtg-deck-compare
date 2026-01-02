import { createRouter, createWebHistory } from 'vue-router';
import Home from '../Home.vue';
import Compare from '../Compare.vue';

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: Home
    },
    {
      path: '/compare',
      name: 'compare',
      component: Compare
    }
  ]
});

export default router;
