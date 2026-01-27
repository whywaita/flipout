import { defineConfig } from 'vite';

export default defineConfig({
  base: '/flipout/',
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
  test: {
    globals: true,
    environment: 'jsdom',
  },
});
