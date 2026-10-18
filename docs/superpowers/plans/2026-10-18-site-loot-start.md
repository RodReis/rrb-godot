# Site Loot Start — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Landing page estática "Loot Start" em `site/`, publicada no GitHub Pages, com dados extraídos em build de `shared/data/heroes`, `docs/roadmap/historia.json` e `docs/STATUS.md`.

**Architecture:** Vite + React 19 + TS, CSS puro com tokens. Um script Node (`site/scripts/extract.mjs`) gera `site/src/data/*.json` e as imagens de `site/public/` antes do `vite build`. O parse de `STATUS.md` sai de `tools/roadmap/build-roadmap.mjs` para `tools/roadmap/status.mjs` e é compartilhado pelo roadmap e pelo site.

**Tech Stack:** Node 24, pnpm, Vite, React 19, TypeScript, sharp (dev), GitHub Actions + Pages.

Spec: `docs/superpowers/specs/2026-10-18-site-loot-start-design.md`.

---

## Arquivos

| Arquivo | Responsabilidade |
|---|---|
| `tools/roadmap/status.mjs` | `parseStatus(statusMd, proplanMd, warn)` → `{ mvps, fatias }` (extraído do gerador) |
| `tools/roadmap/build-roadmap.mjs` | importa `parseStatus`; resto igual |
| `tools/roadmap/build-roadmap.test.mjs` | copia também `status.mjs` para a raiz falsa |
| `site/package.json`, `vite.config.ts`, `tsconfig.json`, `index.html`, `.gitignore` | scaffold |
| `site/scripts/extract.mjs` | `.tres` → `heroes.json`; `historia.json` → cópia + `capturas.json`; `STATUS.md` → `roadmap.json`; imagens → `public/img`, ícones → `public/icons` |
| `site/scripts/tres.mjs` | parser puro de `.tres` (`parseTres(text)`), testável sem FS |
| `site/scripts/tres.test.mjs` | teste do parser |
| `site/src/styles/tokens.css`, `global.css` | tokens e base |
| `site/src/brand/Logo.tsx`, `site/public/favicon.svg` | marca |
| `site/src/hooks/useReveal.ts` | reveal por IntersectionObserver |
| `site/src/components/*.tsx` + `.css` | Nav, Hero, HowItWorks, Heroes, Arena, Gallery, Roadmap, Footer |
| `site/src/data.ts` | tipos + import dos JSON |
| `.github/workflows/ci.yml` | filtro `site` + job `site` |
| `.github/workflows/site.yml` | deploy Pages |

---

### Task 1: extrair `parseStatus` para `tools/roadmap/status.mjs`

**Files:**
- Create: `tools/roadmap/status.mjs`
- Modify: `tools/roadmap/build-roadmap.mjs:46-120`
- Modify: `tools/roadmap/build-roadmap.test.mjs:79`

- [ ] **Step 1: Rodar o teste atual para ter a linha de base**

Run: `node --test tools/roadmap`
Expected: `# pass 2`

- [ ] **Step 2: Criar `tools/roadmap/status.mjs`** (código movido, sem mudar lógica)

```js
// Parse de docs/STATUS.md (§2 marcos, §3 fatias) e .proplan/STATUS.md (estado das Issues).
// Compartilhado por build-roadmap.mjs e site/scripts/extract.mjs. Sem dependências.

function section(md, startRe) {
  const lines = md.split("\n");
  const i = lines.findIndex((l) => startRe.test(l));
  if (i < 0) return [];
  const out = [];
  for (let j = i + 1; j < lines.length && !/^## /.test(lines[j]); j++) out.push(lines[j]);
  return out;
}
const cells = (l) => l.trim().replace(/^\||\|$/g, "").split("|").map((c) => c.trim());

const PROPLAN_STATE = { "backlog": "planejado", "a fazer": "proximo", "em andamento": "construindo",
  "feito": "entregue", "finalizado": "entregue", "descartado": "descartado" };

function estadoDoStatus(t) {
  if (/^(done|finalizado)/.test(t)) return "entregue";
  if (/^doing/.test(t)) return "construindo";
  if (/^todo/.test(t)) return "proximo";
  if (/^cancelad/.test(t)) return "descartado";
  return "planejado";
}

/** @returns {{ mvps: object[], fatias: object[], proplanUpdated: string|null }} */
export function parseStatus(statusMd, proplanMd, warn = () => {}) {
  const mvps = [];
  for (const l of section(statusMd, /^## 2\./)) {
    const m = l.match(/^\|\s*\*{0,2}(MVP\d+(?:\.\d+)?)\*{0,2}\s*\|/);
    if (!m) continue;
    const c = cells(l);
    mvps.push({ id: m[1], entrega: c[1], criterio: c[3] });
  }
  if (!mvps.length) throw new Error("docs/STATUS.md §2: nenhuma linha de MVP encontrada");
  mvps.sort((a, b) => Number(a.id.slice(3)) - Number(b.id.slice(3)));

  const fatias = [];
  for (const l of section(statusMd, /^## 3\./)) {
    if (!/^\|\s*(F\d+|\[GATE\]|\[INFRA\])/.test(l)) continue;
    const c = cells(l);
    if (c.length < 5) continue;
    const kind = c[0].startsWith("[GATE]") ? "GATE" : c[0].startsWith("[INFRA]") ? "INFRA" : "F";
    const f = kind === "F" ? c[0].match(/F\d+/)[0] : kind;
    const issue = (c[4].match(/#(\d+)/) || [])[1] ?? null;
    const estadoTxt = c[4].replace(/\(.*?\)/g, "").trim().toLowerCase();
    fatias.push({ f, kind, mvp: c[1], desc: c[3], issue, estadoTxt });
  }

  const byIssue = new Map();
  const byKey = new Map();
  const proplanUpdated = (proplanMd.match(/^updated:\s*(\S+)/m) || [])[1] ?? null;
  let cur = null;
  for (const l of proplanMd.split("\n")) {
    const h = l.match(/^## (.+)$/);
    if (h) { cur = PROPLAN_STATE[h[1].trim().toLowerCase()] ?? null; continue; }
    if (!cur || !l.startsWith("- ")) continue;
    const iss = (l.match(/\(#(\d+)[,)]/) || [])[1];
    if (iss) byIssue.set(iss, cur);
    const mv = (l.match(/\[(MVP\d+(?:\.\d+)?)\]/) || [])[1];
    const fk = (l.match(/\[(F\d+)\]/) || [])[1];
    if (fk) byKey.set(fk, cur);
    else if (mv && /\[GATE\]/.test(l)) byKey.set(mv + ":GATE", cur);
  }
  for (const x of fatias) {
    const pp = (x.issue && byIssue.get(x.issue)) ?? byKey.get(x.kind === "GATE" ? x.mvp + ":GATE" : x.f);
    const st = estadoDoStatus(x.estadoTxt);
    x.estado = pp ?? st;
    if (pp && pp !== st && !(pp === "entregue" && st === "entregue"))
      warn(`${x.f}${x.kind === "GATE" ? " " + x.mvp : ""}${x.issue ? " (#" + x.issue + ")" : ""}: docs/STATUS.md diz "${x.estadoTxt}", Issues dizem "${pp}" (vale Issues)`);
  }

  for (const m of mvps) {
    const itens = fatias.filter((x) => x.mvp === m.id && x.kind !== "INFRA" && x.estado !== "descartado");
    const gates = itens.filter((x) => x.kind === "GATE");
    m.itens = [...itens.filter((x) => x.kind !== "GATE"), ...gates];
    const n = (e) => m.itens.filter((x) => x.estado === e).length;
    m.total = m.itens.length;
    m.entregues = n("entregue");
    m.estado = m.total && m.entregues === m.total ? "concluido"
      : m.itens.some((x) => x.estado === "entregue" || x.estado === "construindo") ? "andamento" : "planejado";
  }
  return { mvps, fatias, proplanUpdated };
}
```

- [ ] **Step 3: Em `build-roadmap.mjs`, substituir o bloco movido**

Apagar da linha `// ---------- STATUS.md ----------` (46) até a linha `const ORDEM_ESTADO = [...]` inclusive (114; a constante não é usada em mais nada) e o `for (const m of mvps) {...}` que vem logo depois, até a linha anterior a `const atual = ...` (133). `proplanUpdated` continua sendo usado na linha 258 e passa a vir do `parseStatus`. No lugar:

```js
import { parseStatus } from "./status.mjs";
// ...após ler as fontes:
const { mvps, proplanUpdated } = parseStatus(statusMd, proplanMd, warn);
for (const m of mvps) {
  const cap = historia.capitulos?.[m.id] ?? {};
  m.cap = cap;
  if (!cap.titulo) warn(`${m.id}: sem capítulo em historia.json`);
  for (const x of m.itens) {
    const k = x.kind === "GATE" ? "GATE" : x.f;
    x.rotulo = historia.rotulos_fatias?.[k];
    if (!x.rotulo) { warn(`${x.f}: sem rótulo público em historia.json; usando descrição do STATUS.md`); x.rotulo = x.desc.replace(/`/g, "").replace(/^Slice [\d.]+ — /, ""); }
  }
}
```

O `import` vai junto dos outros no topo. Se `ORDEM_ESTADO` for usado no HTML, mantenha a constante no gerador.

- [ ] **Step 4: No teste, copiar `status.mjs` para a raiz falsa**

Em `build-roadmap.test.mjs`, logo após `copyFileSync(GERADOR, ...)`:

```js
copyFileSync(join(dirname(GERADOR), "status.mjs"), join(raiz, "tools", "roadmap", "status.mjs"));
```

- [ ] **Step 5: Rodar teste e o gerador de verdade**

Run: `node --test tools/roadmap`
Expected: `# pass 2`

Run: `node tools/roadmap/build-roadmap.mjs --out "$env:TEMP/roadmap-check.html"` (PowerShell) e `git status --short docs/roadmap` — `index.html` não muda porque a saída foi para temp. Compare: `node tools/roadmap/build-roadmap.mjs --out $env:TEMP/a.html; git stash; node tools/roadmap/build-roadmap.mjs --out $env:TEMP/b.html; git stash pop; fc $env:TEMP/a.html $env:TEMP/b.html` → `FC: no differences encountered`.

- [ ] **Step 6: Commit**

```bash
git add tools/roadmap/status.mjs tools/roadmap/build-roadmap.mjs tools/roadmap/build-roadmap.test.mjs
git commit -m "refactor(roadmap): extrai parseStatus para tools/roadmap/status.mjs"
```

---

### Task 2: scaffold do `site/`

**Files:**
- Create: `site/package.json`, `site/vite.config.ts`, `site/tsconfig.json`, `site/index.html`, `site/.gitignore`, `site/src/main.tsx`, `site/src/App.tsx`, `site/src/vite-env.d.ts`

- [ ] **Step 1: `site/package.json`**

```json
{
  "name": "loot-start-site",
  "private": true,
  "type": "module",
  "scripts": {
    "extract": "node scripts/extract.mjs",
    "dev": "pnpm extract && vite",
    "build": "pnpm extract && tsc --noEmit && vite build",
    "preview": "vite preview",
    "test": "node --test scripts"
  }
}
```

- [ ] **Step 2: instalar dependências (pnpm grava as versões)**

Run (em `site/`): `pnpm add react react-dom` e `pnpm add -D vite @vitejs/plugin-react typescript @types/react @types/react-dom sharp`
Expected: `site/pnpm-lock.yaml` criado; `node_modules/` presente.

- [ ] **Step 3: `site/vite.config.ts`**

```ts
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Pages serve em https://rodreis.github.io/rrb-godot/ ; dev e preview na raiz.
export default defineConfig(({ command }) => ({
  plugins: [react()],
  base: command === "build" ? "/rrb-godot/" : "/",
}));
```

- [ ] **Step 4: `site/tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "skipLibCheck": true,
    "noEmit": true,
    "types": ["vite/client"]
  },
  "include": ["src"]
}
```

- [ ] **Step 5: `site/index.html`**

```html
<!doctype html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="description" content="Loot Start: arena 3D 1x1 de dois tempos. Cinco minutos para crescer, cinco para decidir." />
    <meta name="theme-color" content="#0B1326" />
    <link rel="icon" href="/favicon.svg" type="image/svg+xml" />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@700;900&family=Outfit:wght@400;500;600&family=JetBrains+Mono:wght@700&display=swap" rel="stylesheet" />
    <title>Loot Start — arena 1x1 de dois tempos</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

- [ ] **Step 6: `site/.gitignore`**

```
node_modules/
dist/
src/data/
public/img/
public/icons/
```

- [ ] **Step 7: `src/main.tsx`, `src/App.tsx`, `src/vite-env.d.ts`**

```tsx
// src/main.tsx
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import "./styles/tokens.css";
import "./styles/global.css";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
```

```tsx
// src/App.tsx (provisório; as seções entram nas tasks 5–7)
export default function App() {
  return <main><h1>Loot Start</h1></main>;
}
```

```ts
// src/vite-env.d.ts
/// <reference types="vite/client" />
```

Crie também `src/styles/tokens.css` e `src/styles/global.css` vazios por ora (Task 4 preenche).

- [ ] **Step 8: Verificar que o scaffold compila** (o `extract` ainda não existe: rode `vite build` direto)

Run (em `site/`): `pnpm exec tsc --noEmit && pnpm exec vite build`
Expected: `✓ built in …`, `dist/index.html` existe.

- [ ] **Step 9: Commit**

```bash
git add site/package.json site/pnpm-lock.yaml site/vite.config.ts site/tsconfig.json site/index.html site/.gitignore site/src
git commit -m "feat(site): scaffold Vite + React + TS da landing Loot Start"
```

---

### Task 3: parser `.tres` e `extract.mjs`

**Files:**
- Create: `site/scripts/tres.mjs`, `site/scripts/tres.test.mjs`, `site/scripts/extract.mjs`

- [ ] **Step 1: Teste do parser (falhando)**

```js
// site/scripts/tres.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { parseTres, heroFromTres } from "./tres.mjs";

const TRES = `[gd_resource type="Resource" script_class="HeroData" format=3 uid="uid://x"]

[ext_resource type="Script" path="res://shared/resources/hero_data.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://shared/ui/icons/knight_q.svg" id="icon_q"]

[sub_resource type="Resource" id="q"]
script = ExtResource("2_skill")
id = &"knight_q"
display_name = "Investida"
description = "Avança 6 u e empurra. Dano: base + 75% do ATQ."
icon = ExtResource("icon_q")
cooldown = PackedFloat64Array(8)

[resource]
script = ExtResource("1_script")
id = &"knight"
display_name = "Cavaleiro"
role = "Tanque"
summary = "Absorção de dano."
base_hp = 600.0
skill_q = SubResource("q")
`;

test("parseTres separa ext_resource, sub_resource e resource", () => {
  const t = parseTres(TRES);
  assert.equal(t.ext.icon_q, "res://shared/ui/icons/knight_q.svg");
  assert.equal(t.sub.q.display_name, "Investida");
  assert.equal(t.sub.q.id, "knight_q");            // &"..." vira string
  assert.equal(t.resource.display_name, "Cavaleiro");
  assert.equal(t.resource.base_hp, 600);            // número vira number
  assert.equal(t.resource.skill_q, "q");            // SubResource("q") vira o id
});

test("heroFromTres monta o herói com a skill e o caminho do ícone", () => {
  const h = heroFromTres(TRES);
  assert.equal(h.id, "knight");
  assert.equal(h.role, "Tanque");
  assert.deepEqual(h.skills, [
    { key: "Q", name: "Investida", description: "Avança 6 u e empurra. Dano: base + 75% do ATQ.", icon: "knight_q.svg" },
  ]);
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run (em `site/`): `pnpm test`
Expected: `Cannot find module ... tres.mjs`

- [ ] **Step 3: `site/scripts/tres.mjs`**

```js
// Parser mínimo de .tres (formato texto do Godot 4) para os recursos HeroData.
// Cobre só o que shared/data/heroes usa: seções, strings, &"StringName", números, ExtResource/SubResource.

function parseValue(raw) {
  const v = raw.trim();
  let m;
  if ((m = v.match(/^&?"([\s\S]*)"$/))) return m[1].replace(/\\"/g, '"').replace(/\\n/g, "\n");
  if ((m = v.match(/^(ExtResource|SubResource)\("([^"]+)"\)$/))) return m[2];
  if (/^-?\d+(\.\d+)?$/.test(v)) return Number(v);
  if (v === "true" || v === "false") return v === "true";
  return v; // PackedFloat64Array(...) etc.: fica cru
}

export function parseTres(text) {
  const out = { ext: {}, sub: {}, resource: {} };
  let target = null;
  for (const line of text.replace(/\r\n/g, "\n").split("\n")) {
    const sec = line.match(/^\[(\w+)(.*)\]$/);
    if (sec) {
      const attrs = Object.fromEntries([...sec[2].matchAll(/(\w+)="([^"]*)"/g)].map((a) => [a[1], a[2]]));
      if (sec[1] === "ext_resource") { out.ext[attrs.id] = attrs.path; target = null; }
      else if (sec[1] === "sub_resource") { target = out.sub[attrs.id] = {}; }
      else if (sec[1] === "resource") { target = out.resource; }
      else target = null;
      continue;
    }
    const kv = target && line.match(/^(\w+)\s*=\s*(.+)$/);
    if (kv) target[kv[1]] = parseValue(kv[2]);
  }
  return out;
}

const SKILL_KEYS = [["skill_q", "Q"], ["skill_e", "E"], ["skill_r", "R"]];

export function heroFromTres(text) {
  const t = parseTres(text);
  const r = t.resource;
  const skills = [];
  for (const [field, key] of SKILL_KEYS) {
    const s = t.sub[r[field]];
    if (!s) continue;
    const iconPath = t.ext[s.icon] ?? "";
    skills.push({ key, name: s.display_name, description: s.description, icon: iconPath.split("/").pop() });
  }
  return { id: r.id, name: r.display_name, role: r.role, weapon: r.weapon_name ?? "", summary: r.summary, skills };
}
```

- [ ] **Step 4: Rodar e ver passar**

Run (em `site/`): `pnpm test`
Expected: `# pass 2`

- [ ] **Step 5: `site/scripts/extract.mjs`**

```js
#!/usr/bin/env node
// Gera site/src/data/*.json e as imagens de site/public/ a partir das fontes do monorepo.
// Fontes: shared/data/heroes/*.tres, shared/ui/icons/*.svg, shared/assets/ui/loading/*.png,
//         docs/roadmap/historia.json, docs/roadmap/img/, docs/STATUS.md, .proplan/STATUS.md.
import { readFileSync, writeFileSync, mkdirSync, readdirSync, copyFileSync, existsSync } from "node:fs";
import { join, resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import sharp from "sharp";
import { heroFromTres } from "./tres.mjs";
import { parseStatus } from "../../tools/roadmap/status.mjs";

const SITE = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const ROOT = resolve(SITE, "..");
const P = (...p) => join(ROOT, ...p);
const DATA = join(SITE, "src", "data");
const IMG = join(SITE, "public", "img");
const ICONS = join(SITE, "public", "icons");
for (const d of [DATA, IMG, ICONS]) mkdirSync(d, { recursive: true });
const read = (f) => readFileSync(f, "utf8").replace(/\r\n/g, "\n");
const write = (name, obj) => writeFileSync(join(DATA, name), JSON.stringify(obj, null, 2) + "\n");

// ---- heróis ----
const heroesDir = P("shared", "data", "heroes");
const heroes = readdirSync(heroesDir).filter((f) => f.endsWith(".tres")).sort()
  .map((f) => heroFromTres(read(join(heroesDir, f))));
for (const h of heroes) for (const s of h.skills) {
  const src = P("shared", "ui", "icons", s.icon);
  if (existsSync(src)) copyFileSync(src, join(ICONS, s.icon));
  else { console.warn(`AVISO: ícone ${s.icon} não encontrado`); s.icon = ""; }
}
write("heroes.json", heroes);

// ---- história + capturas ----
const historia = JSON.parse(read(P("docs", "roadmap", "historia.json")));
write("historia.json", historia);
const capturas = [];
for (const [mvp, cap] of Object.entries(historia.capitulos ?? {}))
  for (const img of cap.imagens ?? [])
    if (img.tipo === "entregue" && /\.webp$/.test(img.arquivo)) capturas.push({ ...img, mvp });
for (const c of capturas) {
  const src = P("docs", "roadmap", "img", c.arquivo);
  if (existsSync(src)) copyFileSync(src, join(IMG, c.arquivo));
  else console.warn(`AVISO: captura ${c.arquivo} não encontrada`);
}
write("capturas.json", capturas);

// ---- roadmap ----
const proplanPath = P(".proplan", "STATUS.md");
const { mvps } = parseStatus(read(P("docs", "STATUS.md")), existsSync(proplanPath) ? read(proplanPath) : "", (m) => console.warn("AVISO: " + m));
write("roadmap.json", mvps.map((m) => ({
  id: m.id, entrega: m.entrega, estado: m.estado, entregues: m.entregues, total: m.total,
  titulo: historia.capitulos?.[m.id]?.titulo ?? m.id, pergunta: historia.capitulos?.[m.id]?.pergunta ?? "",
})));

// ---- fundos PNG → WebP ----
for (const name of ["splash", "arena_day", "arena_night", "heroes"]) {
  const src = P("shared", "assets", "ui", "loading", `${name}.png`);
  if (!existsSync(src)) { console.warn(`AVISO: ${name}.png não encontrado`); continue; }
  await sharp(src).resize({ width: 1920, withoutEnlargement: true }).webp({ quality: 78 }).toFile(join(IMG, `${name}.webp`));
}
console.log(`heróis: ${heroes.length} · capturas: ${capturas.length} · MVPs: ${mvps.map((m) => `${m.id} ${m.entregues}/${m.total}`).join(", ")}`);
```

- [ ] **Step 6: Rodar o extract**

Run (em `site/`): `pnpm extract`
Expected: linha `heróis: 6 · capturas: N · MVPs: MVP0 …`; arquivos em `src/data/`, `public/img/*.webp` (4 fundos + capturas), `public/icons/*.svg`. Sem `AVISO` além dos já conhecidos do roadmap.

- [ ] **Step 7: Commit**

```bash
git add site/scripts
git commit -m "feat(site): extract.mjs gera heróis, roadmap, capturas e fundos em build"
```

---

### Task 4: tokens, base CSS, logo, favicon

**Files:**
- Modify: `site/src/styles/tokens.css`, `site/src/styles/global.css`
- Create: `site/src/brand/Logo.tsx`, `site/public/favicon.svg`

- [ ] **Step 1: `tokens.css`** (valores de `docs/design-system/TOKENS.md` §1)

```css
:root {
  --bg-surface: #0b1326;
  --bg-lowest: #060e20;
  --bg-panel: #171f33;
  --bg-card: #222a3d;
  --bg-high: #2d3449;
  --gold: #f59e0b;
  --gold-bright: #ffc174;
  --gold-edge: #78350f;
  --on-gold: #613b00;
  --blue: #3198dc;
  --cyan: #93ccff;
  --red: #ef4444;
  --green: #22c55e;
  --purple: #a855f7;
  --text: #dae2fd;
  --text-muted: #d8c3ad;
  --border: #534434;

  --font-display: "Cinzel", "Times New Roman", serif;
  --font-body: "Outfit", system-ui, sans-serif;
  --font-mono: "JetBrains Mono", ui-monospace, monospace;

  --radius-xs: 4px; --radius-sm: 8px; --radius-md: 12px; --radius-lg: 16px;
  --dur-fast: 0.15s; --dur-base: 0.3s; --dur-slow: 0.6s;
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
  --space-section: clamp(4rem, 3rem + 5vw, 8rem);
  --gutter: clamp(16px, 4vw, 48px);
  --max-w: 1200px;
}
```

- [ ] **Step 2: `global.css`**

```css
*, *::before, *::after { box-sizing: border-box; }
html { scroll-behavior: smooth; }
body {
  margin: 0; background: var(--bg-surface); color: var(--text);
  font-family: var(--font-body); font-size: clamp(15px, 0.9rem + 0.3vw, 17px); line-height: 1.6;
  overflow-x: hidden;
}
img { max-width: 100%; display: block; }
a { color: var(--gold-bright); }
h1, h2, h3 { font-family: var(--font-display); font-weight: 700; line-height: 1.1; margin: 0; letter-spacing: 0.02em; }
h2 { font-size: clamp(1.6rem, 1.2rem + 1.6vw, 2.4rem); text-transform: uppercase; color: var(--gold-bright); }
p { margin: 0; }
:focus-visible { outline: 2px solid var(--gold-bright); outline-offset: 3px; }

.container { width: min(100% - 2 * var(--gutter), var(--max-w)); margin-inline: auto; }
.section { padding-block: var(--space-section); position: relative; }
.eyebrow { font-family: var(--font-mono); font-size: 0.75rem; letter-spacing: 0.2em; text-transform: uppercase; color: var(--text-muted); }
.section-head { display: grid; gap: 0.5rem; margin-bottom: 2.5rem; max-width: 60ch; }
.section-head p { color: var(--text-muted); }

/* painel vidro = PanelCardGlass da HUD */
.glass {
  position: relative; background: color-mix(in srgb, var(--bg-panel) 85%, transparent);
  border: 1px solid color-mix(in srgb, var(--gold) 35%, transparent); border-radius: var(--radius-lg);
  box-shadow: 0 16px 32px -12px rgb(0 0 0 / 0.55); backdrop-filter: blur(8px);
}
.glass::before, .glass::after {
  content: ""; position: absolute; width: 8px; height: 2px; background: var(--gold); pointer-events: none;
}
.glass::before { top: 6px; left: 6px; box-shadow: 0 6px 0 -0px var(--gold); }
.glass::after { bottom: 6px; right: 6px; }

.btn {
  display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.8rem 1.4rem; border-radius: var(--radius-md);
  font-family: var(--font-display); font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; font-size: 0.9rem;
  text-decoration: none; border: 1px solid transparent; transition: transform var(--dur-fast) var(--ease-out), box-shadow var(--dur-fast);
}
.btn:hover { transform: translateY(-2px); }
.btn-primary { background: linear-gradient(180deg, var(--gold-bright), var(--gold)); color: var(--on-gold); border-bottom: 3px solid var(--gold-edge); box-shadow: 0 0 24px -6px var(--gold); }
.btn-primary:hover { box-shadow: 0 0 32px -4px var(--gold); }
.btn-ghost { color: var(--text); border-color: color-mix(in srgb, var(--text) 25%, transparent); background: color-mix(in srgb, var(--bg-surface) 60%, transparent); }
.btn-ghost:hover { border-color: var(--gold); }

.chip { font-family: var(--font-mono); font-size: 0.7rem; letter-spacing: 0.12em; text-transform: uppercase; padding: 0.3rem 0.6rem; border-radius: var(--radius-xs); background: var(--bg-high); color: var(--cyan); }

/* reveal (useReveal) */
.reveal { opacity: 0; transform: translateY(12px); transition: opacity var(--dur-base) var(--ease-out), transform var(--dur-base) var(--ease-out); }
.reveal.is-in { opacity: 1; transform: none; }

/* grain */
.grain::after {
  content: ""; position: absolute; inset: 0; pointer-events: none; opacity: 0.04; mix-blend-mode: overlay;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='160' height='160'><filter id='n'><feTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='2'/></filter><rect width='160' height='160' filter='url(%23n)'/></svg>");
}

@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
  .reveal { opacity: 1; transform: none; transition: none; }
  *, *::before, *::after { animation-duration: 0.01ms !important; animation-iteration-count: 1 !important; transition-duration: 0.01ms !important; }
}
```

- [ ] **Step 3: `src/brand/Logo.tsx`**

```tsx
type Props = { variant?: "horizontal" | "stacked"; size?: number; className?: string };

/** Ícone: baú aberto com um "play" subindo do interior (loot + start). */
export function LogoIcon({ size = 32 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64" aria-hidden="true">
      <defs>
        <linearGradient id="ls-gold" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#ffc174" /><stop offset="1" stopColor="#f59e0b" />
        </linearGradient>
      </defs>
      {/* tampa aberta */}
      <path d="M10 30 L54 30 L50 14 Q32 8 14 14 Z" fill="url(#ls-gold)" stroke="#78350f" strokeWidth="1.5" strokeLinejoin="round" />
      {/* interior */}
      <rect x="14" y="30" width="36" height="7" fill="#0b1326" />
      {/* play subindo */}
      <path d="M26 6 L26 28 L44 17 Z" fill="#dae2fd" />
      {/* corpo */}
      <rect x="10" y="36" width="44" height="20" rx="3" fill="url(#ls-gold)" stroke="#78350f" strokeWidth="1.5" />
      <rect x="18" y="36" width="4" height="20" fill="#78350f" opacity="0.6" />
      <rect x="42" y="36" width="4" height="20" fill="#78350f" opacity="0.6" />
      {/* fechadura */}
      <rect x="28" y="40" width="8" height="9" rx="1.5" fill="#0b1326" />
      <circle cx="32" cy="43.5" r="1.4" fill="#ffc174" />
    </svg>
  );
}

export function Logo({ variant = "horizontal", size = 32, className = "" }: Props) {
  const stacked = variant === "stacked";
  return (
    <span className={`logo ${stacked ? "logo-stacked" : ""} ${className}`} style={{ ["--logo-size" as string]: `${size}px` }}>
      <LogoIcon size={stacked ? size * 2.4 : size} />
      <span className="logo-word">Loot Start</span>
    </span>
  );
}
```

Adicione ao fim de `global.css`:

```css
.logo { display: inline-flex; align-items: center; gap: 0.6em; font-size: var(--logo-size); line-height: 1; text-decoration: none; }
.logo-word {
  font-family: var(--font-display); font-weight: 900; text-transform: uppercase; letter-spacing: 0.12em; font-size: 0.8em;
  background: linear-gradient(180deg, var(--gold-bright) 20%, var(--gold) 80%); -webkit-background-clip: text; background-clip: text; color: transparent;
  filter: drop-shadow(0 1px 0 rgb(120 53 15 / 0.4));
}
.logo-stacked { flex-direction: column; gap: 0.4em; text-align: center; }
.logo-stacked .logo-word { font-size: 1.6em; letter-spacing: 0.16em; }
```

- [ ] **Step 4: `site/public/favicon.svg`** (o mesmo ícone, sem React)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffc174"/><stop offset="1" stop-color="#f59e0b"/></linearGradient></defs><rect width="64" height="64" rx="12" fill="#0b1326"/><path d="M10 30 L54 30 L50 14 Q32 8 14 14 Z" fill="url(#g)" stroke="#78350f" stroke-width="1.5" stroke-linejoin="round"/><rect x="14" y="30" width="36" height="7" fill="#0b1326"/><path d="M26 6 L26 28 L44 17 Z" fill="#dae2fd"/><rect x="10" y="36" width="44" height="20" rx="3" fill="url(#g)" stroke="#78350f" stroke-width="1.5"/><rect x="28" y="40" width="8" height="9" rx="1.5" fill="#0b1326"/></svg>
```

- [ ] **Step 5: Ver no browser**

Em `App.tsx` provisório, renderize `<Logo variant="stacked" size={40} />`. Run (em `site/`): `pnpm dev` e abra `http://localhost:5173`. Esperado: wordmark dourada em Cinzel, ícone legível. Confira o favicon na aba.

- [ ] **Step 6: Commit**

```bash
git add site/src/styles site/src/brand site/public/favicon.svg site/src/App.tsx
git commit -m "feat(site): tokens, base CSS, logo Loot Start e favicon"
```

---

### Task 5: dados tipados, `useReveal`, Nav e Hero

**Files:**
- Create: `site/src/data.ts`, `site/src/hooks/useReveal.ts`, `site/src/components/Nav.tsx`, `Nav.css`, `Hero.tsx`, `Hero.css`
- Modify: `site/src/App.tsx`

- [ ] **Step 1: `src/data.ts`**

```ts
import heroesJson from "./data/heroes.json";
import historiaJson from "./data/historia.json";
import capturasJson from "./data/capturas.json";
import roadmapJson from "./data/roadmap.json";

export type Skill = { key: "Q" | "E" | "R"; name: string; description: string; icon: string };
export type Hero = { id: string; name: string; role: string; weapon: string; summary: string; skills: Skill[] };
export type Faixa = { de: number; ate: number; rotulo: string; curto?: string; detalhe: string; cor: "gold" | "red" | "purple" };
export type Captura = { arquivo: string; legenda: string; tipo: string; mvp: string };
export type Mvp = { id: string; entrega: string; estado: "concluido" | "andamento" | "planejado"; entregues: number; total: number; titulo: string; pergunta: string };
type Historia = {
  projeto: { tagline: string; pitch: string[]; release_url?: string };
  partida: { titulo: string; duracao_total_s: number; faixas: Faixa[]; marcos: { t: number; rotulo: string }[]; regras: string[] };
  pilares: { titulo: string; itens: { nome: string; papel: string; texto: string }[] }[];
  creditos: string[];
};

export const heroes = heroesJson as Hero[];
export const historia = historiaJson as Historia;
export const capturas = capturasJson as Captura[];
export const roadmap = roadmapJson as Mvp[];

export const REPO_URL = "https://github.com/RodReis/rrb-godot";
export const RELEASES_URL = historia.projeto.release_url ?? `${REPO_URL}/releases`;
export const HAS_RELEASE = Boolean(historia.projeto.release_url);
export const img = (file: string) => `${import.meta.env.BASE_URL}img/${file}`;
export const icon = (file: string) => `${import.meta.env.BASE_URL}icons/${file}`;
```

- [ ] **Step 2: `src/hooks/useReveal.ts`**

```ts
import { useEffect } from "react";

/** Marca .reveal com .is-in quando entra na viewport (uma vez). */
export function useReveal() {
  useEffect(() => {
    const els = document.querySelectorAll<HTMLElement>(".reveal");
    if (!("IntersectionObserver" in window)) { els.forEach((e) => e.classList.add("is-in")); return; }
    const io = new IntersectionObserver((entries) => {
      for (const en of entries) if (en.isIntersecting) { en.target.classList.add("is-in"); io.unobserve(en.target); }
    }, { rootMargin: "0px 0px -10% 0px" });
    els.forEach((e) => io.observe(e));
    return () => io.disconnect();
  }, []);
}
```

- [ ] **Step 3: `Nav.tsx` + `Nav.css`**

```tsx
import { Logo } from "../brand/Logo";
import { RELEASES_URL } from "../data";
import "./Nav.css";

const LINKS = [["#como-funciona", "Como funciona"], ["#herois", "Heróis"], ["#arena", "Arena"], ["#roadmap", "Roadmap"]];

export function Nav() {
  return (
    <header className="nav glass">
      <a href="#top" className="nav-logo" aria-label="Loot Start, início"><Logo size={22} /></a>
      <nav aria-label="Seções">
        <details className="nav-menu">
          <summary aria-label="Menu">☰</summary>
          <ul>{LINKS.map(([href, label]) => <li key={href}><a href={href}>{label}</a></li>)}</ul>
        </details>
        <ul className="nav-links">{LINKS.map(([href, label]) => <li key={href}><a href={href}>{label}</a></li>)}</ul>
      </nav>
      <a className="btn btn-primary nav-cta" href={RELEASES_URL}>Baixar</a>
    </header>
  );
}
```

```css
.nav { position: fixed; inset: 12px 12px auto; z-index: 10; display: flex; align-items: center; gap: 1.5rem; padding: 0.6rem 1rem; border-radius: var(--radius-md); }
.nav-logo { text-decoration: none; }
.nav nav { margin-left: auto; }
.nav-links { display: flex; gap: 1.25rem; list-style: none; margin: 0; padding: 0; }
.nav-links a { color: var(--text); text-decoration: none; font-weight: 500; font-size: 0.95rem; transition: color var(--dur-fast); }
.nav-links a:hover { color: var(--gold-bright); }
.nav-cta { padding: 0.5rem 1rem; font-size: 0.75rem; }
.nav-menu { display: none; position: relative; }
.nav-menu summary { list-style: none; cursor: pointer; font-size: 1.4rem; color: var(--gold-bright); padding: 0 0.4rem; }
.nav-menu ul { position: absolute; right: 0; top: 2.4rem; min-width: 180px; list-style: none; margin: 0; padding: 0.5rem; background: var(--bg-panel); border: 1px solid var(--border); border-radius: var(--radius-sm); }
.nav-menu a { display: block; padding: 0.5rem 0.75rem; color: var(--text); text-decoration: none; }
@media (max-width: 767px) { .nav-links { display: none; } .nav-menu { display: block; } .nav { gap: 0.75rem; } }
```

- [ ] **Step 4: `Hero.tsx` + `Hero.css`**

```tsx
import { Logo } from "../brand/Logo";
import { historia, img, RELEASES_URL, REPO_URL, HAS_RELEASE } from "../data";
import "./Hero.css";

export function Hero() {
  return (
    <section id="top" className="hero grain" style={{ backgroundImage: `url(${img("splash.webp")})` }}>
      <div className="hero-fog hero-fog-a" aria-hidden="true" />
      <div className="hero-fog hero-fog-b" aria-hidden="true" />
      <div className="hero-content container">
        <h1 className="hero-title"><Logo variant="stacked" size={40} /></h1>
        <p className="hero-tagline">{historia.projeto.tagline}</p>
        <div className="hero-ctas">
          <a className="btn btn-primary" href={RELEASES_URL}>
            Baixar para Windows{!HAS_RELEASE && <span className="chip hero-soon">em breve</span>}
          </a>
          <a className="btn btn-ghost" href={REPO_URL}>Ver no GitHub</a>
        </div>
        <ul className="hero-chips" aria-label="Resumo">
          <li className="chip">1x1</li><li className="chip">≤ 10 min</li><li className="chip">Godot 4.7</li><li className="chip">Servidor autoritativo</li>
        </ul>
      </div>
      <a className="hero-scroll" href="#como-funciona" aria-label="Rolar para Como funciona">↓</a>
    </section>
  );
}
```

```css
.hero { position: relative; min-height: 100svh; display: grid; place-items: center; background-size: cover; background-position: center 40%; isolation: isolate; }
.hero::before { content: ""; position: absolute; inset: 0; background: linear-gradient(180deg, rgb(11 19 38 / 0.55), rgb(11 19 38 / 0.35) 50%, var(--bg-surface) 100%); }
.hero-fog { position: absolute; inset: -20%; pointer-events: none; opacity: 0.6; will-change: transform; }
.hero-fog-a { background: radial-gradient(60% 40% at 30% 60%, rgb(58 31 58 / 0.55), transparent 70%); animation: fog-a 24s ease-in-out infinite alternate; }
.hero-fog-b { background: radial-gradient(50% 45% at 70% 40%, rgb(40 20 60 / 0.5), transparent 70%); animation: fog-b 30s ease-in-out infinite alternate; }
@keyframes fog-a { from { transform: translate3d(-3%, 0, 0); } to { transform: translate3d(3%, 2%, 0); } }
@keyframes fog-b { from { transform: translate3d(3%, 1%, 0); } to { transform: translate3d(-3%, -2%, 0); } }
.hero-content { position: relative; z-index: 1; display: grid; justify-items: center; gap: 1.5rem; text-align: center; padding-block: 6rem; }
.hero-title { font-size: 1rem; }
.hero-title .logo-stacked .logo-word { font-size: clamp(2rem, 1rem + 5vw, 4.2rem); text-shadow: 0 0 40px rgb(245 158 11 / 0.35); }
.hero-tagline { max-width: 36ch; font-size: clamp(1.05rem, 0.9rem + 0.6vw, 1.35rem); color: var(--text); text-shadow: 0 2px 12px rgb(0 0 0 / 0.6); }
.hero-ctas { display: flex; flex-wrap: wrap; justify-content: center; gap: 0.75rem; }
.hero-soon { margin-left: 0.5rem; background: var(--on-gold); color: var(--gold-bright); }
.hero-chips { display: flex; flex-wrap: wrap; justify-content: center; gap: 0.5rem; list-style: none; margin: 0; padding: 0; }
.hero-scroll { position: absolute; bottom: 1.5rem; left: 50%; translate: -50% 0; color: var(--gold-bright); text-decoration: none; font-size: 1.4rem; animation: bob 1.6s ease-in-out infinite; }
@keyframes bob { 50% { transform: translateY(6px); } }
```

- [ ] **Step 5: `App.tsx`**

```tsx
import { Nav } from "./components/Nav";
import { Hero } from "./components/Hero";
import { useReveal } from "./hooks/useReveal";

export default function App() {
  useReveal();
  return (
    <>
      <Nav />
      <main>
        <Hero />
      </main>
    </>
  );
}
```

- [ ] **Step 6: Verificar** `pnpm dev` → hero em tela cheia com o splash, logo, CTA "Baixar para Windows · em breve". Reduza a janela a 375 px: menu ☰ aparece, sem rolagem horizontal.

- [ ] **Step 7: Commit**

```bash
git add site/src
git commit -m "feat(site): nav, hero com splash e dados tipados"
```

---

### Task 6: Como funciona e Heróis

**Files:**
- Create: `site/src/components/HowItWorks.tsx`, `HowItWorks.css`, `Heroes.tsx`, `Heroes.css`
- Modify: `site/src/App.tsx`

- [ ] **Step 1: `HowItWorks.tsx` + css**

```tsx
import { historia } from "../data";
import "./HowItWorks.css";

const mmss = (s: number) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;

export function HowItWorks() {
  const { partida, projeto } = historia;
  const total = partida.duracao_total_s;
  return (
    <section id="como-funciona" className="section container">
      <div className="section-head reveal">
        <span className="eyebrow">Como funciona</span>
        <h2>{partida.titulo}</h2>
        <p>{projeto.pitch[0]}</p>
      </div>
      <div className="timeline glass reveal" role="img" aria-label={`Linha do tempo da partida: ${partida.faixas.map((f) => `${f.rotulo} de ${mmss(f.de)} a ${mmss(f.ate)}`).join("; ")}`}>
        <div className="timeline-bar">
          {partida.faixas.map((f) => (
            <div key={f.rotulo} className={`timeline-seg seg-${f.cor}`} style={{ flexGrow: f.ate - f.de }}>
              <strong>{f.rotulo}</strong><small>{f.detalhe}</small>
            </div>
          ))}
        </div>
        <ul className="timeline-marks">
          {partida.marcos.map((m) => (
            <li key={m.t} style={{ left: `${(m.t / total) * 100}%` }}><span>{mmss(m.t)}</span>{m.rotulo}</li>
          ))}
        </ul>
      </div>
      <ul className="rules">
        {partida.regras.map((r, i) => <li key={i} className="glass reveal"><span className="rule-n">{i + 1}</span>{r}</li>)}
      </ul>
    </section>
  );
}
```

```css
.timeline { padding: 1.5rem 1.5rem 4.5rem; }
.timeline-bar { display: flex; gap: 4px; height: 72px; }
.timeline-seg { display: grid; align-content: center; padding: 0 1rem; border-radius: var(--radius-sm); min-width: 0; }
.timeline-seg strong { font-family: var(--font-display); font-size: 0.9rem; letter-spacing: 0.06em; text-transform: uppercase; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.timeline-seg small { color: var(--text-muted); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.seg-gold { background: color-mix(in srgb, var(--gold) 28%, var(--bg-card)); border-left: 3px solid var(--gold); }
.seg-red { background: color-mix(in srgb, var(--red) 28%, var(--bg-card)); border-left: 3px solid var(--red); }
.seg-purple { background: color-mix(in srgb, var(--purple) 28%, var(--bg-card)); border-left: 3px solid var(--purple); }
.timeline-marks { position: relative; height: 3rem; margin: 0.5rem 0 0; padding: 0; list-style: none; }
.timeline-marks li { position: absolute; top: 0; translate: -50% 0; display: grid; justify-items: center; font-size: 0.75rem; color: var(--text-muted); text-align: center; white-space: nowrap; }
.timeline-marks li::before { content: ""; width: 1px; height: 10px; background: var(--border); }
.timeline-marks span { font-family: var(--font-mono); color: var(--cyan); }
.timeline-marks li:first-child { translate: 0 0; } .timeline-marks li:last-child { translate: -100% 0; }
.rules { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 1rem; margin: 1.5rem 0 0; padding: 0; list-style: none; }
.rules li { padding: 1.25rem 1.25rem 1.25rem 3.4rem; position: relative; }
.rule-n { position: absolute; left: 1.1rem; top: 1.1rem; font-family: var(--font-mono); color: var(--gold); font-size: 1.4rem; }
@media (max-width: 640px) { .timeline-seg small { display: none; } .timeline-marks li:nth-child(even) { top: 1.6rem; } }
```

- [ ] **Step 2: `Heroes.tsx` + css**

```tsx
import { heroes, icon, img } from "../data";
import "./Heroes.css";

export function Heroes() {
  return (
    <section id="herois" className="section heroes grain" style={{ backgroundImage: `url(${img("heroes.webp")})` }}>
      <div className="container">
        <div className="section-head reveal">
          <span className="eyebrow">Heróis</span>
          <h2>{heroes.length} heróis, três habilidades cada</h2>
          <p>Nome, papel e habilidades vêm dos mesmos arquivos de dados que o jogo usa.</p>
        </div>
        <ul className="hero-grid">
          {heroes.map((h) => (
            <li key={h.id} className="hero-card glass reveal">
              <header>
                <h3>{h.name}</h3>
                <span className="chip">{h.role}{h.weapon && ` · ${h.weapon}`}</span>
              </header>
              <p>{h.summary}</p>
              <ul className="skills">
                {h.skills.map((s) => (
                  <li key={s.key} title={`${s.name}: ${s.description}`}>
                    {s.icon ? <img src={icon(s.icon)} alt="" width="48" height="48" loading="lazy" /> : <span className="skill-fallback" />}
                    <span className="skill-key">{s.key}</span>
                    <span className="skill-name">{s.name}</span>
                  </li>
                ))}
              </ul>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
```

```css
.heroes { background-size: cover; background-position: center; isolation: isolate; }
.heroes::before { content: ""; position: absolute; inset: 0; z-index: -1; background: linear-gradient(180deg, var(--bg-surface), rgb(11 19 38 / 0.82) 30%, rgb(11 19 38 / 0.82) 70%, var(--bg-surface)); }
.hero-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 1.25rem; margin: 0; padding: 0; list-style: none; }
.hero-card { padding: 1.5rem; display: grid; gap: 0.9rem; transition: border-color var(--dur-fast), transform var(--dur-fast) var(--ease-out); }
.hero-card:hover { border-color: var(--gold); transform: translateY(-4px); }
.hero-card header { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 0.5rem; }
.hero-card h3 { font-size: 1.3rem; color: var(--gold-bright); }
.hero-card p { color: var(--text-muted); font-size: 0.95rem; }
.skills { display: grid; grid-template-columns: repeat(3, 1fr); gap: 0.6rem; margin: 0; padding: 0; list-style: none; }
.skills li { position: relative; display: grid; justify-items: center; gap: 0.35rem; font-size: 0.78rem; text-align: center; }
.skills img, .skill-fallback { width: 48px; height: 48px; border-radius: var(--radius-sm); border: 2px solid var(--border); background: var(--bg-card); }
.skill-key { position: absolute; top: 34px; right: calc(50% - 30px); font-family: var(--font-display); font-size: 0.6rem; padding: 0 4px; background: var(--gold); color: var(--on-gold); border-radius: 3px; }
.skill-name { color: var(--text); line-height: 1.2; }
```

- [ ] **Step 3: Adicionar em `App.tsx`** (dentro de `<main>`, após `<Hero />`): `<HowItWorks />` e `<Heroes />` com os imports.

- [ ] **Step 4: Verificar** `pnpm dev`: linha do tempo com 3 faixas e 4 marcos; 6 cards com ícones Q/E/R. Em 375 px: 1 coluna, marcos alternando altura.

- [ ] **Step 5: Commit**

```bash
git add site/src
git commit -m "feat(site): seções Como funciona (linha do tempo) e Heróis (dados dos .tres)"
```

---

### Task 7: Arena + Galeria, Roadmap, Rodapé

**Files:**
- Create: `site/src/components/Arena.tsx`, `Arena.css`, `Gallery.tsx`, `Gallery.css`, `Roadmap.tsx`, `Roadmap.css`, `Footer.tsx`, `Footer.css`
- Modify: `site/src/App.tsx`

- [ ] **Step 1: `Arena.tsx` + css**

```tsx
import { historia, img } from "../data";
import { Gallery } from "./Gallery";
import "./Arena.css";

export function Arena() {
  const bestiario = historia.pilares.find((p) => /besti/i.test(p.titulo));
  return (
    <section id="arena" className="section arena">
      <div className="arena-bg" aria-hidden="true">
        <img src={img("arena_day.webp")} alt="" className="arena-day" />
        <img src={img("arena_night.webp")} alt="" className="arena-night" />
      </div>
      <div className="container">
        <div className="section-head reveal">
          <span className="eyebrow">Arena</span>
          <h2>Um vale, dois portões, um centro disputado</h2>
          <p>{historia.projeto.pitch[0].split(". ")[1] ?? historia.projeto.tagline}</p>
        </div>
        {bestiario && (
          <ul className="beasts">
            {bestiario.itens.map((b) => (
              <li key={b.nome} className="glass reveal"><strong>{b.nome}</strong><span className="chip">{b.papel}</span><p>{b.texto}</p></li>
            ))}
          </ul>
        )}
        <Gallery />
      </div>
    </section>
  );
}
```

```css
.arena { isolation: isolate; }
.arena-bg { position: absolute; inset: 0; z-index: -1; overflow: hidden; }
.arena-bg img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; }
.arena-bg::after { content: ""; position: absolute; inset: 0; background: linear-gradient(180deg, var(--bg-surface), rgb(11 19 38 / 0.85) 25%, rgb(11 19 38 / 0.85) 75%, var(--bg-surface)); }
.arena-night { animation: daynight 16s ease-in-out infinite; }
@keyframes daynight { 0%, 40% { opacity: 0; } 60%, 90% { opacity: 1; } 100% { opacity: 0; } }
.beasts { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 1rem; margin: 0 0 3rem; padding: 0; list-style: none; }
.beasts li { padding: 1.1rem; display: grid; gap: 0.4rem; justify-items: start; }
.beasts strong { font-family: var(--font-display); color: var(--gold-bright); }
.beasts p { color: var(--text-muted); font-size: 0.92rem; }
```

- [ ] **Step 2: `Gallery.tsx` + css** (lightbox com `<dialog>` nativo)

```tsx
import { useEffect, useRef, useState } from "react";
import { capturas, img } from "../data";
import "./Gallery.css";

export function Gallery() {
  const [i, setI] = useState<number | null>(null);
  const dlg = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const d = dlg.current;
    if (!d) return;
    if (i === null) { if (d.open) d.close(); return; }
    if (!d.open) d.showModal();
  }, [i]);

  const step = (d: number) => setI((v) => (v === null ? v : (v + d + capturas.length) % capturas.length));

  return (
    <>
      <h3 className="gallery-title reveal">Capturas do jogo</h3>
      <ul className="gallery">
        {capturas.map((c, k) => (
          <li key={c.arquivo} className="reveal">
            <button type="button" onClick={() => setI(k)} aria-label={`Ampliar: ${c.legenda}`}>
              <img src={img(c.arquivo)} alt={c.legenda} loading="lazy" width="640" height="360" />
              <span className="chip">{c.mvp}</span>
            </button>
          </li>
        ))}
      </ul>
      <dialog ref={dlg} className="lightbox" onClose={() => setI(null)}
        onKeyDown={(e) => { if (e.key === "ArrowRight") step(1); if (e.key === "ArrowLeft") step(-1); }}
        onClick={(e) => { if (e.target === dlg.current) setI(null); }}>
        {i !== null && (
          <figure>
            <img src={img(capturas[i].arquivo)} alt={capturas[i].legenda} />
            <figcaption>{capturas[i].legenda}</figcaption>
            <div className="lightbox-nav">
              <button type="button" onClick={() => step(-1)} aria-label="Anterior">‹</button>
              <span className="chip">{i + 1} / {capturas.length}</span>
              <button type="button" onClick={() => step(1)} aria-label="Próxima">›</button>
              <button type="button" onClick={() => setI(null)} aria-label="Fechar">×</button>
            </div>
          </figure>
        )}
      </dialog>
    </>
  );
}
```

```css
.gallery-title { font-size: 1.2rem; color: var(--gold-bright); margin-bottom: 1rem; }
.gallery { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 0.9rem; margin: 0; padding: 0; list-style: none; }
.gallery button { position: relative; padding: 0; border: 1px solid var(--border); border-radius: var(--radius-sm); overflow: hidden; background: var(--bg-card); cursor: pointer; width: 100%; transition: border-color var(--dur-fast), transform var(--dur-fast) var(--ease-out); }
.gallery button:hover { border-color: var(--gold); transform: translateY(-3px); }
.gallery img { aspect-ratio: 16 / 9; object-fit: cover; width: 100%; }
.gallery .chip { position: absolute; left: 8px; bottom: 8px; }
.lightbox { border: 0; padding: 0; background: transparent; max-width: min(96vw, 1400px); }
.lightbox::backdrop { background: rgb(6 14 32 / 0.9); }
.lightbox figure { margin: 0; display: grid; gap: 0.75rem; justify-items: center; }
.lightbox img { max-height: 80vh; border-radius: var(--radius-sm); border: 1px solid var(--border); }
.lightbox figcaption { color: var(--text-muted); text-align: center; max-width: 70ch; }
.lightbox-nav { display: flex; align-items: center; gap: 0.75rem; }
.lightbox-nav button { background: var(--bg-panel); color: var(--gold-bright); border: 1px solid var(--border); border-radius: var(--radius-sm); font-size: 1.4rem; width: 44px; height: 44px; cursor: pointer; }
```

- [ ] **Step 3: `Roadmap.tsx` + css**

```tsx
import { roadmap, REPO_URL } from "../data";
import "./Roadmap.css";

const LABEL = { concluido: "Concluído", andamento: "Em andamento", planejado: "Planejado" } as const;

export function Roadmap() {
  return (
    <section id="roadmap" className="section container">
      <div className="section-head reveal">
        <span className="eyebrow">Roadmap</span>
        <h2>O que já existe e o que falta</h2>
        <p>Cada marco responde a uma pergunta. O estado vem direto do quadro de trabalho do projeto.</p>
      </div>
      <ol className="mvps">
        {roadmap.map((m) => (
          <li key={m.id} className={`mvp glass reveal is-${m.estado}`}>
            <header>
              <span className="eyebrow">{m.id}</span>
              <span className={`mvp-state state-${m.estado}`}>{LABEL[m.estado]}</span>
            </header>
            <h3>{m.titulo}</h3>
            {m.pergunta && <p className="mvp-q">{m.pergunta}</p>}
            <div className="mvp-bar" role="progressbar" aria-valuemin={0} aria-valuemax={m.total} aria-valuenow={m.entregues} aria-label={`${m.entregues} de ${m.total} entregas`}>
              <span style={{ width: m.total ? `${(m.entregues / m.total) * 100}%` : 0 }} />
            </div>
            <small>{m.entregues}/{m.total} entregas</small>
          </li>
        ))}
      </ol>
      <p className="roadmap-more reveal">Versão longa, com capturas e aprendizados: <a href={`${REPO_URL}/blob/main/docs/roadmap/index.html`}>roadmap completo no repositório</a>.</p>
    </section>
  );
}
```

```css
.mvps { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 1rem; margin: 0; padding: 0; list-style: none; counter-reset: mvp; }
.mvp { padding: 1.25rem; display: grid; gap: 0.5rem; align-content: start; }
.mvp header { display: flex; justify-content: space-between; align-items: center; }
.mvp h3 { font-size: 1.1rem; }
.mvp-q { color: var(--text-muted); font-size: 0.9rem; }
.mvp-state { font-family: var(--font-mono); font-size: 0.65rem; letter-spacing: 0.1em; text-transform: uppercase; padding: 0.2rem 0.5rem; border-radius: var(--radius-xs); }
.state-concluido { background: color-mix(in srgb, var(--gold) 25%, transparent); color: var(--gold-bright); }
.state-andamento { background: color-mix(in srgb, var(--blue) 30%, transparent); color: var(--cyan); }
.state-planejado { background: var(--bg-high); color: var(--text-muted); }
.mvp-bar { height: 6px; background: var(--bg-lowest); border-radius: 3px; overflow: hidden; margin-top: auto; }
.mvp-bar span { display: block; height: 100%; background: linear-gradient(90deg, var(--gold), var(--gold-bright)); transition: width var(--dur-slow) var(--ease-out); }
.is-andamento .mvp-bar span { background: linear-gradient(90deg, var(--blue), var(--cyan)); }
.mvp small { color: var(--text-muted); font-family: var(--font-mono); font-size: 0.7rem; }
.roadmap-more { margin-top: 1.5rem; color: var(--text-muted); }
```

- [ ] **Step 4: `Footer.tsx` + css**

```tsx
import { Logo } from "../brand/Logo";
import { historia, REPO_URL } from "../data";
import "./Footer.css";

export function Footer() {
  return (
    <footer className="footer">
      <div className="container footer-grid">
        <div>
          <Logo size={20} />
          <p>Projeto solo de aprendizado e portfólio. Godot 4, GDScript, servidor autoritativo.</p>
          <a href={REPO_URL}>Código no GitHub</a>
        </div>
        <div>
          <span className="eyebrow">Créditos</span>
          <ul>{historia.creditos.map((c) => <li key={c}>{c}</li>)}</ul>
        </div>
      </div>
    </footer>
  );
}
```

```css
.footer { background: var(--bg-lowest); border-top: 1px solid var(--border); padding-block: 3rem; color: var(--text-muted); font-size: 0.9rem; }
.footer-grid { display: grid; grid-template-columns: 1fr 1.4fr; gap: 2rem; }
.footer p { margin: 0.75rem 0; max-width: 40ch; }
.footer ul { margin: 0.5rem 0 0; padding-left: 1.1rem; display: grid; gap: 0.3rem; }
@media (max-width: 640px) { .footer-grid { grid-template-columns: 1fr; } }
```

- [ ] **Step 5: `App.tsx` completo**

```tsx
import { Nav } from "./components/Nav";
import { Hero } from "./components/Hero";
import { HowItWorks } from "./components/HowItWorks";
import { Heroes } from "./components/Heroes";
import { Arena } from "./components/Arena";
import { Roadmap } from "./components/Roadmap";
import { Footer } from "./components/Footer";
import { useReveal } from "./hooks/useReveal";

export default function App() {
  useReveal();
  return (
    <>
      <Nav />
      <main>
        <Hero />
        <HowItWorks />
        <Heroes />
        <Arena />
        <Roadmap />
      </main>
      <Footer />
    </>
  );
}
```

- [ ] **Step 6: Build completo**

Run (em `site/`): `pnpm build`
Expected: extract OK, `tsc` sem erro, `✓ built`. `dist/` contém `img/` e `icons/`.

- [ ] **Step 7: Commit**

```bash
git add site/src
git commit -m "feat(site): arena com galeria, roadmap por MVP e rodapé"
```

---

### Task 8: CI e deploy no GitHub Pages

**Files:**
- Modify: `.github/workflows/ci.yml` (filtro `site`, job `site`, `gate.needs`)
- Create: `.github/workflows/site.yml`

- [ ] **Step 1: filtro e job no `ci.yml`**

Em `changes.outputs` adicionar `site: ${{ steps.filter.outputs.site }}`; em `filters` adicionar `site: ['site/**', 'tools/roadmap/**', 'shared/data/heroes/**', 'docs/roadmap/historia.json', 'docs/STATUS.md']`. Novo job antes de `gate`:

```yaml
  site:
    needs: changes
    if: needs.changes.outputs.site == 'true' || needs.changes.outputs.infra == 'true'
    runs-on: ubuntu-latest
    timeout-minutes: 6
    defaults:
      run:
        working-directory: site
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          package_json_file: site/package.json
      - uses: actions/setup-node@v4
        with:
          node-version: 24
          cache: pnpm
          cache-dependency-path: site/pnpm-lock.yaml
      - run: pnpm install --frozen-lockfile
      - run: pnpm test
      - name: roadmap parser (tools/roadmap)
        run: node --test ../tools/roadmap
      - run: pnpm build
```

E em `gate`: `needs: [changes, lint-gd, test-game, test-launcher, test-backend, site]`.

- [ ] **Step 2: `.github/workflows/site.yml`**

```yaml
name: site

on:
  push:
    branches: [main]
    paths: ['site/**', 'tools/roadmap/**', 'shared/data/heroes/**', 'shared/ui/icons/**', 'shared/assets/ui/loading/**', 'docs/roadmap/**', 'docs/STATUS.md', '.proplan/STATUS.md', '.github/workflows/site.yml']
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 8
    defaults:
      run:
        working-directory: site
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          package_json_file: site/package.json
      - uses: actions/setup-node@v4
        with:
          node-version: 24
          cache: pnpm
          cache-dependency-path: site/pnpm-lock.yaml
      - run: pnpm install --frozen-lockfile
      - run: pnpm build
      - uses: actions/upload-pages-artifact@v3
        with:
          path: site/dist
  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

- [ ] **Step 3: Validar YAML localmente**

Run: `node -e "require('fs').readFileSync('.github/workflows/site.yml','utf8')"` apenas confirma leitura; a validação real é o CI da PR. Confira indentação a olho.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ci.yml .github/workflows/site.yml
git commit -m "ci(site): job de build no CI e deploy no GitHub Pages"
```

**Nota para o PI:** o deploy só funciona depois de ativar **Settings → Pages → Source: GitHub Actions** no repositório. Até lá o workflow `site` falha no job `deploy`.

---

### Task 9: verificação visual e PR

- [ ] **Step 1: Preview de produção**

Run (em `site/`): `pnpm build && pnpm preview --port 4173`. Abra `http://localhost:4173/` no browser da sessão em 1440, 768 e 375 px. Tire screenshot de cada largura. Checar: sem rolagem horizontal; nav colapsa em 375; linha do tempo legível; galeria abre e fecha com Esc; `prefers-reduced-motion` desliga neblina (emular no DevTools).

- [ ] **Step 2: Lighthouse rápido** (DevTools → Lighthouse, desktop): Acessibilidade ≥ 95, Performance ≥ 85. Se o splash pesar demais, baixar `quality` do `sharp` para 70.

- [ ] **Step 3: Docs**

Em `docs/DEVELOPMENT.md` e `docs/STATUS.md` §1 ("Agora") acrescentar uma linha: "Site público `site/` (landing Loot Start, GitHub Pages) — fora do board, pedido do PI em 2026-10-18; ADR-0002 a atualizar pelo Cowork (3º módulo)". `README.md`: seção curta "Site" com `pnpm -C site dev`.

- [ ] **Step 4: Commit e PR**

```bash
git add docs/DEVELOPMENT.md docs/STATUS.md README.md
git commit -m "docs(site): registra o site público e o comando de dev"
git push -u origin feat/site
gh pr create --title "feat(site): landing Loot Start em site/ com deploy no GitHub Pages" --body "..."
gh pr checks --watch
```

Corpo da PR: o que é, de onde vêm os dados, screenshots das 3 larguras, nota do Pages, nota do ADR-0002.
