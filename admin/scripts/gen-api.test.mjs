// O models.ts commitado tem de bater com o backend/openapi.json (a CI roda este teste).
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import { generate } from './gen-api.mjs';

test('src/api/models.ts está em dia com backend/openapi.json', () => {
  const spec = JSON.parse(readFileSync(new URL('../../backend/openapi.json', import.meta.url), 'utf8'));
  const committed = readFileSync(new URL('../src/api/models.ts', import.meta.url), 'utf8');
  assert.equal(committed, generate(spec), 'rode `pnpm gen:api` e commite src/api/models.ts');
});
