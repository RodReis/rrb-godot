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
  MatchHistoryDto: 'MatchHistory',
};
// Objeto aninhado sem $ref: "Schema.propriedade" -> class_name. Em array, vale para o item
// ("Schema.matches" = classe de cada elemento) e o caminho dos filhos continua em "Schema.matches.x".
const NESTED = {
  'TicketStatusDto.assignment': 'MatchAssignment',
  'MatchHistoryDto.totals': 'MatchTotals',
  'MatchHistoryDto.matches': 'MatchSummary',
  'MatchHistoryDto.matches.me': 'MatchMine',
  'MatchHistoryDto.matches.opponent': 'MatchOpponent',
};

const spec = JSON.parse(readFileSync(join(ROOT, 'backend', 'openapi.json'), 'utf8'));
const snake = (name) => name.replace(/[A-Z]/g, (c) => `_${c.toLowerCase()}`);
const files = {};

// OpenAPI 3.1 (`type: [x, "null"]`) ou 3.0 (`nullable`): o tipo base e se aceita nulo.
function baseType(prop) {
  const nullable = prop.nullable === true || (Array.isArray(prop.type) && prop.type.includes('null'));
  const type = Array.isArray(prop.type) ? prop.type.find((t) => t !== 'null') : prop.type;
  return { type, nullable };
}

// Nulo no backend fica com o valor inicial; inteiro nulo fica -1 (0 seria um valor valido).
function gdType(prop, nested) {
  const { type, nullable } = baseType(prop);
  if (type === 'array') {
    if (!nested) throw new Error(`array sem classe em NESTED: ${JSON.stringify(prop)}`);
    return { type: `Array[${nested}]`, init: '[]' };
  }
  if (nested) return { type: nested, init: 'null' };
  if (type === 'integer') return { type: 'int', init: nullable ? '-1' : '0' };
  if (type === 'number') return { type: 'float', init: '0.0' };
  if (type === 'boolean') return { type: 'bool', init: 'false' };
  if (type === 'string') return { type: 'String', init: '""' };
  throw new Error(`tipo sem mapeamento: ${JSON.stringify(prop)}`);
}

// Linhas que leem `data[key]` para `model.field`; `return null` quando o valor nao serve.
function readField(key, field, prop, nested) {
  const value = `data["${key}"]`;
  const { type } = baseType(prop);
  if (type === 'array') {
    return [
      `if not ${value} is Array:`,
      '	return null',
      `for entry: Variant in ${value}:`,
      `	var parsed := ${nested}.from_dict(entry)`,
      '	if parsed == null:',
      '		return null',
      `	model.${field}.append(parsed)`,
    ];
  }
  if (nested) {
    return [`model.${field} = ${nested}.from_dict(${value})`, `if model.${field} == null:`, '	return null'];
  }
  if (type === 'integer' || type === 'number') {
    const cast = type === 'integer' ? 'int' : 'float';
    const check = type === 'integer' ? ` or not is_equal_approx(${value}, roundf(${value}))` : '';
    return [
      `if not (${value} is float or ${value} is int)${check}:`,
      '	return null',
      `model.${field} = ${cast}(${value})`,
    ];
  }
  const kind = type === 'boolean' ? 'bool' : 'String';
  const lines = [`if not ${value} is ${kind}:`, '	return null'];
  if (prop.enum) lines.push(`if not ${value} in [${prop.enum.map((e) => `"${e}"`).join(', ')}]:`, '	return null');
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
    `## ${schemaName} do backend.`,
    '## from_dict devolve null se o JSON nao bater com o contrato.',
    '',
  ];
  const body = [];
  for (const [key, prop] of props) {
    const nested = NESTED[`${schemaName}.${key}`];
    if (nested) files[nested] = generate(`${schemaName}.${key}`, prop.items ?? prop, nested);
    const field = snake(key);
    const { type, init } = gdType(prop, nested);
    if (!required.has(key)) lines.push('## Opcional: fica com o valor inicial quando nao vem.');
    lines.push(`var ${field}: ${type} = ${init}`);
    const read = readField(key, field, prop, nested);
    if (required.has(key) && baseType(prop).nullable) {
      // Presente, mas pode ser nulo: nulo deixa o valor inicial.
      body.push(`if not data.has("${key}"):`, '\treturn null', `if data["${key}"] != null:`, ...read.map((l) => `\t${l}`));
    } else if (required.has(key)) {
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
