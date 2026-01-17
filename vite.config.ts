import vue from '@vitejs/plugin-vue';
import { URL, fileURLToPath } from 'node:url';
import { defineConfig } from 'vite';

// https://vitejs.dev/config/
export default defineConfig(() => {
  const backend_host = process.env['DOCKER'] ? 'server' : 'localhost';
  return {
    plugins: [vue()],
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./web/src', import.meta.url))
      }
    },
    root: './web',
    build: {
      outDir: '../public',
      emptyOutDir: true
    },
    server: {
      proxy: {
        '/api': { target: `http://${backend_host}:9292`, changeOrigin: true }
      },
      open: '/',
      watch: {
        usePolling: true
      }
    }
  };
});
