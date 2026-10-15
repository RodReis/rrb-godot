// Gera launcher/scripts/models/*.gd a partir de backend/openapi.json (ARCHITECTURE-LAUNCHER §3.1).
// Uso (na raiz), depois de `pnpm -C backend openapi`:
//   node tools/launcher/gen_models.mjs && gdformat launcher/scripts/models
// Cada model e um RefCounted com campos snake_case e `from_dict(data) -> Model`, que devolve null
// se faltar campo obrigatorio ou o tipo nao bater (o Launcher nunca confia no JSON recebido).
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const OUT = join(ROOT, 'launcher', 'scripts', 'models');
// Schema do OpenAPI -> class_name. So o que o Launcher le; erro ({code, message}) e do ApiClient.
const MODELS = {
  AuthTokensDto: 'AuthTokens',
  UserProfileDto: 'UserProfile',
  QueueTicketDto: 'QueueTicket',
  TicketStatusDto: 'TicketStatus',
};
// Objeto aninhado sem $ref: "Schema.propriedade" -> class_name.
const NESTED = { 'TicketStatusDto.assignment': 'MatchAssignment' };

const spec = JSON.parse(readFileSync(join(ROOT, 'backend', 'openapi.json'), 'utf8'));
const snake = (name) => name.replace(/[A-Z]/g, (c) => `_${c.toLowerCase()}`);
const files = {};

function gdType(prop, nested) {
  if (nested) return { type: nested, init: 'null' };
  if (prop.type === 'integer') return { type: 'int', init: '0' };
  if (prop.type === 'number') return { type: 'float', init: '0.0' };
  if (prop.type === 'boolean') return { type: 'bool', init: 'false' };
  if (prop.type === 'string') return { type: 'String', init: '""' };
  throw new Error(`tipo sem mapeamento: ${JSON.stringify(prop)}`);
}

// Linhas que leem `data[key]` para `model.field`; `return null` quando o valor nao serve.
function readField(key, field, prop, nested) {
  const value = `data["${key}"]`;
  if (nested) {
    return [`model.${field} = ${nested}.from_dict(${value})`, `if model.${field} == null:`, '\treturn null'];
  }
  if (prop.type === 'integer' || prop.type === 'number') {
    const cast = prop.type === 'integer' ? 'int' : 'float';
    const check = prop.type === 'integer' ? ` or not is_equal_approx(${value}, roundf(${value}))` : '';
    return [
      `if not (${value} is float or ${value} is int)${check}:`,
      '\treturn null',
      `model.${field} = ${cast}(${value})`,
    ];
  }
  const kind = prop.type === 'boolean' ? 'bool' : 'String';
  const lines = [`if not ${value} is ${kind}:`, '\treturn null'];
  if (prop.enum) lines.push(`if not ${value} in [${prop.enum.map((e) => `"${e}"`).join(', ')}]:`, '\treturn null');
  lines.push(`model.${field} = ${value}`);
  return lines;
}

function generate(schemaName, schema, className) {
  const required = new Set(schema.required ?? []);
  const props = Object.entries(schema.properties);
  const lines = [
    '# GERADO por tools/launcher/gen_models.mjs a partir de backend/openapi.json. Nao editar.',
    `class_name ${className}`,
    'extends RefCounted',
    `## ${schemaName} do backend. from_dict devolve null se o JSON nao bater com o contrato.`,
    '',
  ];
  const body = [];
  for (const [key, prop] of props) {
    const nested = NESTED[`${schemaName}.${key}`];
    if (nested) files[nested] = generate(`${schemaName}.${key}`, prop, nested);
    const field = snake(key);
    const { type, init } = gdType(prop, nested);
    if (!required.has(key)) lines.push('## Opcional: fica com o valor inicial quando nao vem.');
    lines.push(`var ${field}: ${type} = ${init}`);
    const read = readField(key, field, prop, nested);
    if (required.has(key)) {
      body.push(`if not data.has("${key}"):`, '\treturn null', ...read);
    } else {
      body.push(`if data.get("${key}") != null:`, ...read.map((l) => `\t${l}`));
    }
  }
  lines.push(
    '',
    '',
    `static func from_dict(raw: Variant) -> ${className}:`,
    '\tif not raw is Dictionary:',
    '\t\treturn null',
    '\tvar data: Dictionary = raw',
    `\tvar model := ${className}.new()`,
    ...body.map((l) => `\t${l}`),
    '\treturn model',
    '',
  );
  return lines.join('\n');
}

for (const [schemaName, className] of Object.entries(MODELS)) {
  const schema = spec.components.schemas[schemaName];
  if (!schema) throw new Error(`schema ausente no openapi.json: ${schemaName}`);
  files[className] = generate(schemaName, schema, className);
}
mkdirSync(OUT, { recursive: true });
for (const [className, source] of Object.entries(files)) {
  writeFileSync(join(OUT, `${snake(className).slice(1)}.gd`), source);
  console.log(`gerado: launcher/scripts/models/${snake(className).slice(1)}.gd`);
}
