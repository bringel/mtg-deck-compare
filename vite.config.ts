import vue from '@vitejs/plugin-vue'
import { URL, fileURLToPath } from 'node:url'
import { defineConfig } from 'vite'

// https://vitejs.dev/config/
export default defineConfig({
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
  }
})
