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
const warn = (m) => console.warn("AVISO: " + m);

// ---- heróis ----
const heroesDir = P("shared", "data", "heroes");
const heroes = readdirSync(heroesDir).filter((f) => f.endsWith(".tres")).sort()
  .map((f) => heroFromTres(read(join(heroesDir, f))));
for (const h of heroes) for (const s of h.skills) {
  const src = P("shared", "ui", "icons", s.icon);
  if (existsSync(src)) copyFileSync(src, join(ICONS, s.icon));
  else { warn(`ícone ${s.icon} não encontrado`); s.icon = ""; }
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
  else warn(`captura ${c.arquivo} não encontrada`);
}
write("capturas.json", capturas);

// ---- roadmap ----
const proplanPath = P(".proplan", "STATUS.md");
const { mvps } = parseStatus(read(P("docs", "STATUS.md")), existsSync(proplanPath) ? read(proplanPath) : "", warn);
write("roadmap.json", mvps.map((m) => ({
  id: m.id, entrega: m.entrega, estado: m.estado, entregues: m.entregues, total: m.total,
  titulo: historia.capitulos?.[m.id]?.titulo ?? m.id, pergunta: historia.capitulos?.[m.id]?.pergunta ?? "",
})));

// ---- fundos PNG → WebP ----
for (const name of ["splash", "arena_day", "arena_night", "heroes"]) {
  const src = P("shared", "assets", "ui", "loading", `${name}.png`);
  if (!existsSync(src)) { warn(`${name}.png não encontrado`); continue; }
  await sharp(src).resize({ width: 1920, withoutEnlargement: true }).webp({ quality: 78 }).toFile(join(IMG, `${name}.webp`));
}
console.log(`heróis: ${heroes.length} · capturas: ${capturas.length} · MVPs: ${mvps.map((m) => `${m.id} ${m.entregues}/${m.total}`).join(", ")}`);
