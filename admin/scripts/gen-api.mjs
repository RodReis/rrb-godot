// Gera src/api/models.ts a partir de backend/openapi.json (como tools/launcher/gen_models.mjs faz para
// o Launcher). Escrito a mão porque o openapi-typescript precisa da API do compilador do TypeScript,
// que o TypeScript 7 (o mesmo do site/) não tem. Só os schemas que o painel lê.
//   pnpm gen:api        (depois de `pnpm -C backend build && pnpm -C backend openapi`)
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const SPEC = join(ROOT, '..', 'backend', 'openapi.json');
const OUT = join(ROOT, 'src', 'api', 'models.ts');

/** Schema do OpenAPI -> nome do tipo exportado. Erro ({ code, message }) é tratado no cliente. */
export const MODELS = {
  AuthTokensDto: 'AuthTokens',
  KpiReportDto: 'KpiReport',
  AdminMatchListDto: 'AdminMatchList',
};

function typeOf(schema, indent) {
  if (schema.$ref) {
    const name = MODELS[schema.$ref.split('/').pop()];
    if (!name) throw new Error(`$ref fora de MODELS: ${schema.$ref}`);
    return name;
  }
  const kinds = Array.isArray(schema.type) ? schema.type : [schema.type];
  const nullable = schema.nullable === true || kinds.includes('null');
  const kind = kinds.find((k) => k !== 'null');
  const base = baseType(schema, kind, indent);
  return nullable ? `${base} | null` : base;
}

function baseType(schema, kind, indent) {
  if (kind === 'string') return schema.enum ? schema.enum.map((v) => JSON.stringify(v)).join(' | ') : 'string';
  if (kind === 'integer' || kind === 'number') return 'number';
  if (kind === 'boolean') return 'boolean';
  if (kind === 'array') return `Array<${typeOf(schema.items, indent)}>`;
  if (kind === 'object') {
    const required = new Set(schema.required ?? []);
    const pad = '  '.repeat(indent + 1);
    const fields = Object.entries(schema.properties ?? {}).map(
      ([key, prop]) => `${pad}${key}${required.has(key) ? '' : '?'}: ${typeOf(prop, indent + 1)};`,
    );
    return `{\n${fields.join('\n')}\n${'  '.repeat(indent)}}`;
  }
  throw new Error(`tipo sem mapeamento: ${JSON.stringify(schema)}`);
}

export function generate(spec) {
  const out = [
    '// GERADO por scripts/gen-api.mjs a partir de backend/openapi.json. Não edite à mão.',
    '',
  ];
  for (const [schema, name] of Object.entries(MODELS)) {
    const def = spec.components.schemas[schema];
    if (!def) throw new Error(`schema ausente no openapi.json: ${schema}`);
    out.push(`export type ${name} = ${typeOf(def, 0)};`, '');
  }
  return out.join('\n');
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  writeFileSync(OUT, generate(JSON.parse(readFileSync(SPEC, 'utf8'))));
  console.log(`gerado ${OUT}`);
}
