import js from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  { ignores: ['dist/', 'coverage/', 'drizzle/migrations/'] },
  js.configs.recommended,
  tseslint.configs.recommended,
);
