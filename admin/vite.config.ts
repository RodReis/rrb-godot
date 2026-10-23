import react from '@vitejs/plugin-react';
import { defineConfig } from 'vitest/config';

// O backend serve o build em /admin-ui (SPEC-029); a API mora na mesma origem, sem CORS.
// Em `pnpm dev` o proxy leva /auth e /admin/ ao backend local (padrão http://127.0.0.1:3000).
const API = process.env.ADMIN_API_URL ?? 'http://127.0.0.1:3000';

export default defineConfig({
  base: '/admin-ui/',
  plugins: [react()],
  server: { proxy: { '/auth': API, '/admin/': API } },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['src/test-setup.ts'],
    include: ['src/**/*.test.{ts,tsx}'],
  },
});
