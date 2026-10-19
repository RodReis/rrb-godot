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

const historia = JSON.parse(read(P("docs", "roadmap", "historia.json")));

// ---- heróis ----
const heroesDir = P("shared", "data", "heroes");
const heroes = readdirSync(heroesDir).filter((f) => f.endsWith(".tres")).sort()
  .map((f) => heroFromTres(read(join(heroesDir, f))));
// ordem de lançamento = ordem do pilar "Heróis" de historia.json; herói fora da lista vai para o fim (ordem de arquivo)
const ordem = (historia.pilares ?? []).find((p) => /herói/i.test(p.titulo))?.itens.map((i) => i.nome) ?? [];
const rank = (h) => { const i = ordem.indexOf(h.name); return i < 0 ? ordem.length : i; };
heroes.sort((a, b) => rank(a) - rank(b));
for (const h of heroes) if (!ordem.includes(h.name)) warn(`herói ${h.name} não está no pilar de heróis de historia.json`);
for (const h of heroes) for (const s of h.skills) {
  const src = P("shared", "ui", "icons", s.icon);
  if (existsSync(src)) copyFileSync(src, join(ICONS, s.icon));
  else { warn(`ícone ${s.icon} não encontrado`); s.icon = ""; }
}
// retratos 512 px de shared/assets/ui/heroes/large -> WebP 384 px (nome = id do herói)
mkdirSync(join(IMG, "heroes"), { recursive: true });
for (const h of heroes) {
  const src = P("shared", "assets", "ui", "heroes", "large", `${h.id}.png`);
  if (existsSync(src)) {
    await sharp(src).resize({ width: 384 }).webp({ quality: 82 }).toFile(join(IMG, "heroes", `${h.id}.webp`));
    h.portrait = `heroes/${h.id}.webp`;
  } else { warn(`retrato de ${h.id} não encontrado`); h.portrait = ""; }
}
write("heroes.json", heroes);

// ---- história + capturas ----
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
capturas.reverse(); // mais recentes primeiro
write("capturas.json", capturas);

// ---- roadmap ----
const proplanPath = P(".proplan", "STATUS.md");
const { mvps } = parseStatus(read(P("docs", "STATUS.md")), existsSync(proplanPath) ? read(proplanPath) : "", warn);
write("roadmap.json", mvps.map((m) => ({
  id: m.id, entrega: m.entrega, estado: m.estado, entregues: m.entregues, total: m.total,
  titulo: historia.capitulos?.[m.id]?.titulo ?? m.id, pergunta: historia.capitulos?.[m.id]?.pergunta ?? "",
})));

// ---- fundos PNG → WebP ----
for (const name of ["arena_day", "arena_night", "heroes"]) {
  const src = P("shared", "assets", "ui", "loading", `${name}.png`);
  if (!existsSync(src)) { warn(`${name}.png não encontrado`); continue; }
  await sharp(src).resize({ width: 1920, withoutEnlargement: true }).webp({ quality: 78 }).toFile(join(IMG, `${name}.webp`));
}
// mapa da arena visto de cima (o mesmo do Launcher)
{
  const src = P("shared", "assets", "ui", "arena_map.png");
  if (existsSync(src)) await sharp(src).resize({ width: 1600 }).webp({ quality: 80 }).toFile(join(IMG, "arena_map.webp"));
  else warn("arena_map.png não encontrado");
}
console.log(`heróis: ${heroes.length} · capturas: ${capturas.length} · MVPs: ${mvps.map((m) => `${m.id} ${m.entregues}/${m.total}`).join(", ")}`);
