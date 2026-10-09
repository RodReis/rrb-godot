#!/usr/bin/env node
// Gera docs/roadmap/index.html (página única, imagens embutidas) a partir de:
//   docs/roadmap/historia.json   — narrativa, rótulos públicos, imagens (autoral)
//   .proplan/STATUS.md           — estado das Issues (vence quando existe a issue)
//   docs/STATUS.md §2 e §3       — lista de MVPs e fatias (fonte da numeração)
//   docs/design-system/TOKENS.md — cores (§1)
// Uso: node tools/roadmap/build-roadmap.mjs [--out caminho] [--fragment caminho]
// Sem dependências: só Node 18+.

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join, dirname, extname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const P = (...p) => join(ROOT, ...p);
const IMG_DIR = P("docs", "roadmap", "img");
const MAX_BYTES = 15 * 1024 * 1024;

const args = process.argv.slice(2);
const argVal = (k) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : null; };
const outFull = resolve(argVal("--out") ?? P("docs", "roadmap", "index.html"));
const outFragment = argVal("--fragment") ? resolve(argVal("--fragment")) : null;

const warnings = [];
const warn = (m) => { warnings.push(m); console.warn("AVISO: " + m); };
const read = (f) => readFileSync(f, "utf8").replace(/\r\n/g, "\n");

// ---------- fontes ----------
const historia = JSON.parse(read(P("docs", "roadmap", "historia.json")));
const statusMd = read(P("docs", "STATUS.md"));
const proplanPath = P(".proplan", "STATUS.md");
const proplanMd = existsSync(proplanPath) ? read(proplanPath) : "";
if (!proplanMd) warn(".proplan/STATUS.md ausente: estado vem só de docs/STATUS.md §3");
const tokensMd = read(P("docs", "design-system", "TOKENS.md"));

// ---------- tokens ----------
const TOKEN_DEFAULTS = {
  BG_SURFACE: "#0B1326", BG_PANEL: "#171F33", BG_CARD: "#222A3D", GOLD: "#F59E0B", GOLD_BRIGHT: "#FFC174",
  BLUE: "#3198DC", CYAN: "#93CCFF", RED: "#EF4444", GREEN: "#22C55E", PURPLE: "#A855F7",
  TEXT: "#DAE2FD", TEXT_MUTED: "#D8C3AD", BORDER: "#534434",
};
const tokens = { ...TOKEN_DEFAULTS };
for (const m of tokensMd.matchAll(/^\|\s*`([A-Z_]+)`\s*\|\s*`(#[0-9A-Fa-f]{6})`/gm)) tokens[m[1]] = m[2].toUpperCase();
for (const k of Object.keys(TOKEN_DEFAULTS)) if (!new RegExp("`" + k + "`").test(tokensMd)) warn(`token ${k} não achado em TOKENS.md; usando padrão`);

// ---------- STATUS.md ----------
function section(md, startRe) {
  const lines = md.split("\n");
  const i = lines.findIndex((l) => startRe.test(l));
  if (i < 0) return [];
  const out = [];
  for (let j = i + 1; j < lines.length && !/^## /.test(lines[j]); j++) out.push(lines[j]);
  return out;
}
const cells = (l) => l.trim().replace(/^\||\|$/g, "").split("|").map((c) => c.trim());

const mvps = [];
for (const l of section(statusMd, /^## 2\./)) {
  const m = l.match(/^\|\s*\*{0,2}(MVP\d+)\*{0,2}\s*\|/);
  if (!m) continue;
  const c = cells(l);
  mvps.push({ id: m[1], entrega: c[1], criterio: c[3] });
}
if (!mvps.length) throw new Error("docs/STATUS.md §2: nenhuma linha de MVP encontrada");

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

// ---------- .proplan/STATUS.md ----------
const PROPLAN_STATE = { "backlog": "planejado", "a fazer": "proximo", "em andamento": "construindo",
  "feito": "entregue", "finalizado": "entregue", "descartado": "descartado" };
const byIssue = new Map();
const byKey = new Map();
let proplanUpdated = (proplanMd.match(/^updated:\s*(\S+)/m) || [])[1] ?? null;
let cur = null;
for (const l of proplanMd.split("\n")) {
  const h = l.match(/^## (.+)$/);
  if (h) { cur = PROPLAN_STATE[h[1].trim().toLowerCase()] ?? null; continue; }
  if (!cur || !l.startsWith("- ")) continue;
  const iss = (l.match(/\(#(\d+)[,)]/) || [])[1];
  if (iss) byIssue.set(iss, cur);
  const mv = (l.match(/\[(MVP\d+)\]/) || [])[1];
  const fk = (l.match(/\[(F\d+)\]/) || [])[1];
  if (fk) byKey.set(fk, cur);
  else if (mv && /\[GATE\]/.test(l)) byKey.set(mv + ":GATE", cur);
}

function estadoDoStatus(t) {
  if (/^(done|finalizado)/.test(t)) return "entregue";
  if (/^doing/.test(t)) return "construindo";
  if (/^todo/.test(t)) return "proximo";
  if (/^cancelad/.test(t)) return "descartado";
  return "planejado";
}
for (const x of fatias) {
  const pp = (x.issue && byIssue.get(x.issue)) ?? byKey.get(x.kind === "GATE" ? x.mvp + ":GATE" : x.f);
  const st = estadoDoStatus(x.estadoTxt);
  x.estado = pp ?? st;
  if (pp && pp !== st && !(pp === "entregue" && st === "entregue"))
    warn(`${x.f}${x.kind === "GATE" ? " " + x.mvp : ""}${x.issue ? " (#" + x.issue + ")" : ""}: docs/STATUS.md diz "${x.estadoTxt}", Issues dizem "${pp}" (vale Issues)`);
}

// ---------- montar MVPs ----------
const ORDEM_ESTADO = ["entregue", "construindo", "proximo", "planejado"];
for (const m of mvps) {
  const cap = historia.capitulos?.[m.id] ?? {};
  m.cap = cap;
  const itens = fatias.filter((x) => x.mvp === m.id && x.kind !== "INFRA" && x.estado !== "descartado");
  const gates = itens.filter((x) => x.kind === "GATE");
  m.itens = [...itens.filter((x) => x.kind !== "GATE"), ...gates];
  const n = (e) => m.itens.filter((x) => x.estado === e).length;
  m.total = m.itens.length;
  m.entregues = n("entregue");
  m.estado = m.total && m.entregues === m.total ? "concluido"
    : m.itens.some((x) => x.estado === "entregue" || x.estado === "construindo") ? "andamento" : "planejado";
  if (!cap.titulo) warn(`${m.id}: sem capítulo em historia.json`);
  for (const x of m.itens) {
    const k = x.kind === "GATE" ? "GATE" : x.f;
    x.rotulo = historia.rotulos_fatias?.[k];
    if (!x.rotulo) { warn(`${x.f}: sem rótulo público em historia.json; usando descrição do STATUS.md`); x.rotulo = x.desc.replace(/`/g, "").replace(/^Slice [\d.]+ — /, ""); }
  }
}
const atual = mvps.find((m) => m.estado !== "concluido") ?? mvps[mvps.length - 1];
const totalItens = mvps.reduce((s, m) => s + m.total, 0);
const totalEntregues = mvps.reduce((s, m) => s + m.entregues, 0);

// ---------- imagens ----------
const MIME = { ".webp": "image/webp", ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
  ".gif": "image/gif", ".svg": "image/svg+xml", ".webm": "video/webm", ".mp4": "video/mp4" };
let embeddedBytes = 0;
function media(img) {
  if (!img?.arquivo) return null;
  const f = join(IMG_DIR, img.arquivo);
  const mime = MIME[extname(f).toLowerCase()];
  if (!mime) { warn(`imagem ${img.arquivo}: extensão não suportada`); return null; }
  if (!existsSync(f)) { warn(`imagem ${img.arquivo} não encontrada em docs/roadmap/img/ — omitida`); return null; }
  const buf = readFileSync(f);
  if (buf.length > 4 * 1024 * 1024) warn(`imagem ${img.arquivo} tem ${(buf.length / 1048576).toFixed(1)} MB; reduza (alvo ≤ 400 KB, vídeo ≤ 3 MB)`);
  embeddedBytes += buf.length;
  return { ...img, src: `data:${mime};base64,${buf.toString("base64")}`, video: mime.startsWith("video/") };
}

// ---------- HTML ----------
const esc = (s) => String(s ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
const ESTADO_FATIA = { entregue: "Entregue", construindo: "Em construção", proximo: "Próximo", planejado: "Planejado" };
const ESTADO_MVP = { concluido: "Concluído", andamento: "Em andamento", planejado: "Planejado" };
const TIPO_IMG = { entregue: "Captura do jogo", "em-construcao": "Em construção", conceito: "Conceito", diagrama: "Diagrama" };
const mmss = (s) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;

function figura(img, cls = "") {
  const m = media(img);
  if (!m) return "";
  const tipo = m.tipo in TIPO_IMG ? m.tipo : "conceito";
  const el = m.video
    ? `<video src="${m.src}" autoplay muted loop playsinline aria-label="${esc(m.legenda)}"></video>`
    : `<img src="${m.src}" alt="${esc(m.legenda)}">`;
  return `<figure class="fig ${cls}" data-tipo="${tipo}">
  <button class="fig-open" type="button" aria-label="Ampliar: ${esc(m.legenda)}">${el}</button>
  <span class="chip tipo-${tipo}">${TIPO_IMG[tipo]}</span>
  <figcaption>${esc(m.legenda)}</figcaption>
</figure>`;
}

function segmentos(m) {
  if (!m.total) return `<div class="segs vazio" aria-hidden="true"></div>`;
  return `<div class="segs" role="img" aria-label="${m.entregues} de ${m.total} entregas concluídas">${m.itens
    .map((x) => `<i class="seg s-${x.estado}" title="${esc(x.rotulo)} — ${ESTADO_FATIA[x.estado]}"></i>`).join("")}</div>`;
}

const rota = mvps.map((m) => `
<a class="no m-${m.estado}${m === atual ? " atual" : ""}" href="#${m.id.toLowerCase()}">
  <span class="no-id">${m.id}</span>
  <span class="no-titulo">${esc(m.cap.titulo ?? m.entrega)}</span>
  ${segmentos(m)}
  <span class="no-estado">${ESTADO_MVP[m.estado]} · ${m.entregues}/${m.total}</span>
</a>`).join("");

const partida = historia.partida;
const pct = (s) => ((s / partida.duracao_total_s) * 100).toFixed(3) + "%";
const timeline = partida ? `
<section class="bloco" id="partida" aria-labelledby="partida-h">
  <p class="eyebrow">O jogo</p>
  <h2 id="partida-h">${esc(partida.titulo)}</h2>
  <div class="relogio" role="img" aria-label="Linha do tempo de uma partida de 0:00 a ${mmss(partida.duracao_total_s)}">
    <div class="marcos marcos-cima">${partida.marcos.filter((_, i) => i % 2 === 0).map((k) =>
      `<span class="marco" style="left:${pct(k.t)}"><b>${mmss(k.t)}</b> ${esc(k.rotulo)}</span>`).join("")}</div>
    <div class="faixas">${partida.faixas.map((f) =>
      `<div class="faixa f-${esc(f.cor)}" style="left:${pct(f.de)};width:calc(${pct(f.ate - f.de)} - 3px)"><span>${esc(f.curto ?? f.rotulo)}</span></div>`).join("")}
      ${partida.marcos.map((k) => `<i class="tick" style="left:${pct(k.t)}"></i>`).join("")}
    </div>
    <div class="marcos marcos-baixo">${partida.marcos.filter((_, i) => i % 2 === 1).map((k) =>
      `<span class="marco" style="left:${pct(k.t)}"><b>${mmss(k.t)}</b> ${esc(k.rotulo)}</span>`).join("")}</div>
  </div>
  <ul class="faixas-legenda">${partida.faixas.map((f) =>
    `<li><i class="dot f-${esc(f.cor)}"></i><b>${esc(f.rotulo)}</b> <span class="mono">${mmss(f.de)}–${mmss(f.ate)}</span><span class="det">${esc(f.detalhe)}</span></li>`).join("")}</ul>
  <ul class="regras">${partida.regras.map((r) => `<li>${esc(r)}</li>`).join("")}</ul>
</section>` : "";

const pilares = (historia.pilares ?? []).map((p) => `
<article class="pilar">
  <h3>${esc(p.titulo)}</h3>
  <dl>${p.itens.map((i) => `<div><dt>${esc(i.nome)} <span class="papel">${esc(i.papel)}</span></dt><dd>${esc(i.texto)}</dd></div>`).join("")}</dl>
</article>`).join("");

const capitulos = mvps.map((m) => {
  const c = m.cap;
  const imgs = (c.imagens ?? []).map((i) => figura(i)).filter(Boolean).join("");
  const nums = (c.numeros ?? []).map((n) => `<div class="num"><b>${esc(n.valor)}</b><span>${esc(n.rotulo)}</span></div>`).join("");
  const lista = m.itens.map((x) => `<li class="it s-${x.estado}"><span class="it-chip">${ESTADO_FATIA[x.estado]}</span><span class="it-txt">${esc(x.rotulo)}</span></li>`).join("");
  const crit = m.criterio ? `<p class="criterio"><span class="mono">Pronto quando</span> ${esc(m.criterio.replace(/`/g, ""))}</p>` : "";
  return `
<article class="cap m-${m.estado}${m === atual ? " atual" : ""}" id="${m.id.toLowerCase()}">
  <div class="cap-trilho" aria-hidden="true"><span class="hex">${m.id.replace("MVP", "")}</span></div>
  <div class="cap-corpo">
    <header class="cap-head">
      <p class="cap-meta"><span class="mono">${m.id}</span><span class="chip est-${m.estado}">${ESTADO_MVP[m.estado]}</span>${c.periodo ? `<span class="mono">${esc(c.periodo)}</span>` : ""}</p>
      <h3>${esc(c.titulo ?? m.entrega)}</h3>
      ${c.pergunta ? `<p class="pergunta">${esc(c.pergunta)}</p>` : ""}
    </header>
    <div class="cap-grid${imgs || nums ? "" : " so-texto"}">
      <div class="cap-texto">
        ${(c.narrativa ?? []).map((p) => `<p>${esc(p)}</p>`).join("")}
        ${c.aprendizado ? `<p class="aprendizado"><span class="mono">Aprendizado</span> ${esc(c.aprendizado)}</p>` : ""}
        ${crit}
      </div>
      ${imgs || nums ? `<div class="cap-lado">${nums ? `<div class="nums">${nums}</div>` : ""}${imgs}</div>` : ""}
    </div>
    <div class="cap-entregas">
      <div class="cap-entregas-head"><span class="mono">Entregas</span><span class="mono">${m.entregues}/${m.total}</span></div>
      ${segmentos(m)}
      <ul class="itens">${lista}</ul>
    </div>
  </div>
</article>`;
}).join("");

const gal = historia.galeria_conceito;
const galeria = gal ? `
<section class="bloco" id="conceito" aria-labelledby="conceito-h">
  <p class="eyebrow">Direção de arte</p>
  <h2 id="conceito-h">${esc(gal.titulo)}</h2>
  <p class="aviso">${esc(gal.aviso)}</p>
  <div class="galeria">${gal.imagens.map((i) => figura(i)).join("")}</div>
</section>` : "";

const pj = historia.projeto;
const capa = media(pj.imagem_capa);
const atualizado = proplanUpdated ?? new Date().toISOString().slice(0, 10);
const dataBR = atualizado.split("-").reverse().join("/");

const CSS = `
/* Layout: tela do launcher — barra de topo, painéis sobre fundo ardósia, rota de marcos MVP0→MVP4, capítulos com trilho hexagonal. Cores: docs/design-system/TOKENS.md. */
:root{
  --bg:${tokens.BG_SURFACE};--panel:${tokens.BG_PANEL};--card:${tokens.BG_CARD};
  --gold:${tokens.GOLD};--gold-b:${tokens.GOLD_BRIGHT};--blue:${tokens.BLUE};--cyan:${tokens.CYAN};
  --red:${tokens.RED};--green:${tokens.GREEN};--purple:${tokens.PURPLE};
  --text:${tokens.TEXT};--muted:${tokens.TEXT_MUTED};--border:${tokens.BORDER};
  --line:color-mix(in srgb,var(--text) 10%,transparent);
  --f-display:"Space Grotesk","Segoe UI",system-ui,sans-serif;
  --f-body:"Outfit","Segoe UI",system-ui,sans-serif;
  --f-mono:"JetBrains Mono",ui-monospace,Consolas,monospace;
  --r:8px;--r-sm:4px;
  color-scheme:dark;
}
*{box-sizing:border-box}
html{scroll-behavior:smooth}
body{margin:0;background:var(--bg);color:var(--text);font:400 16px/1.6 var(--f-body);
  background-image:radial-gradient(1200px 600px at 80% -10%,color-mix(in srgb,var(--blue) 14%,transparent),transparent 70%),
  radial-gradient(900px 500px at -10% 30%,color-mix(in srgb,var(--gold) 7%,transparent),transparent 70%);background-attachment:fixed}
a{color:var(--gold-b)}
:focus-visible{outline:3px solid var(--gold-b);outline-offset:3px}
.mono{font-family:var(--f-mono);font-size:.75rem;font-weight:700;letter-spacing:.06em;text-transform:uppercase;color:var(--muted)}
h1,h2,h3{font-family:var(--f-display);font-weight:700;line-height:1.1;text-wrap:balance;margin:0}
.wrap{max-width:1180px;margin:0 auto;padding-inline:clamp(16px,4vw,40px)}

/* barra de topo */
.topo{position:sticky;top:env(safe-area-inset-top,0px);z-index:10;background:color-mix(in srgb,var(--bg) 88%,transparent);
  backdrop-filter:blur(12px);border-bottom:1px solid var(--line)}
.topo .wrap{display:flex;align-items:center;gap:16px;min-height:60px;flex-wrap:wrap;padding-block:8px}
.marca{display:flex;align-items:center;gap:10px;text-decoration:none;color:var(--gold-b)}
.marca svg{flex:none}
.marca b{font:700 1.05rem/1 var(--f-display);text-transform:uppercase;letter-spacing:.02em}
.marca small{display:block;font:700 .62rem/1.3 var(--f-mono);letter-spacing:.14em;color:var(--muted);text-transform:uppercase}
.nav{display:flex;gap:4px;margin-left:auto;flex-wrap:wrap}
.nav a{font:600 .95rem/1 var(--f-display);text-transform:uppercase;letter-spacing:.03em;color:var(--text);text-decoration:none;padding:10px 12px;border-radius:var(--r-sm)}
.nav a:hover{background:var(--card);color:var(--gold-b)}
@media (max-width:720px){.nav{display:none}}

/* chips */
.chip{display:inline-flex;align-items:center;gap:6px;font:700 .68rem/1 var(--f-mono);letter-spacing:.08em;text-transform:uppercase;
  padding:6px 9px;clip-path:polygon(6px 0,100% 0,100% calc(100% - 6px),calc(100% - 6px) 100%,0 100%,0 6px);
  background:var(--card);color:var(--text)}
.est-concluido{background:color-mix(in srgb,var(--green) 22%,var(--panel));color:#B9F5CF}
.est-andamento{background:var(--gold);color:var(--bg)}
.est-planejado{background:var(--card);color:var(--muted)}
.tipo-conceito{background:color-mix(in srgb,var(--purple) 35%,var(--panel));color:#EBD9FF}
.tipo-em-construcao{background:var(--gold);color:var(--bg)}
.tipo-entregue{background:var(--green);color:var(--bg)}
.tipo-diagrama{background:color-mix(in srgb,var(--blue) 35%,var(--panel));color:#D6ECFF}

/* capa */
.capa{position:relative;margin-top:24px;border:2px solid var(--border);border-radius:var(--r);overflow:hidden;background:var(--panel);
  display:grid;grid-template-columns:minmax(0,1fr)}
.capa-arte{grid-area:1/1;position:relative;min-height:420px}
.capa-arte img{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;object-position:60% 40%}
.capa-arte::after{content:"";position:absolute;inset:0;background:linear-gradient(90deg,var(--bg) 0%,color-mix(in srgb,var(--bg) 85%,transparent) 38%,color-mix(in srgb,var(--bg) 10%,transparent) 75%),
  linear-gradient(0deg,var(--bg),transparent 40%)}
.capa-txt{grid-area:1/1;position:relative;z-index:1;padding:clamp(24px,5vw,56px);max-width:640px;display:flex;flex-direction:column;gap:18px;align-self:center}
.capa-txt h1{font-size:clamp(2.4rem,6vw,4rem);text-transform:uppercase;letter-spacing:-.02em;color:var(--gold-b)}
.capa-txt h1 small{display:block;font:700 .75rem/1 var(--f-mono);letter-spacing:.14em;color:var(--muted);margin-top:10px}
.tagline{font:600 clamp(1.1rem,2.2vw,1.35rem)/1.4 var(--f-display);margin:0}
.capa-txt p{margin:0;max-width:60ch}
.capa-leg{position:absolute;right:12px;bottom:12px;z-index:1;display:flex;gap:8px;align-items:center;max-width:min(420px,calc(100% - 24px));
  font-size:.78rem;color:var(--muted);background:color-mix(in srgb,var(--bg) 80%,transparent);padding:6px 8px;border-radius:var(--r-sm)}
.capa-leg .chip{flex:none}
.stack{display:flex;flex-wrap:wrap;gap:6px}
.stack span{font:700 .7rem/1 var(--f-mono);letter-spacing:.04em;color:var(--cyan);border:1px solid color-mix(in srgb,var(--cyan) 35%,transparent);padding:6px 8px;border-radius:var(--r-sm)}
@media (max-width:720px){
  .capa-arte{min-height:220px}
  .capa-arte::after{background:linear-gradient(0deg,var(--panel) 2%,transparent 70%)}
  .capa{grid-template-rows:auto auto}.capa-arte{grid-area:1/1}.capa-txt{grid-area:2/1;padding-top:8px}
  .capa-leg{position:static;grid-area:3/1;margin:0 16px 16px}
}

/* rota */
.rota-bloco{margin-top:28px}
.rota-head{display:flex;justify-content:space-between;align-items:baseline;gap:12px;flex-wrap:wrap;margin-bottom:12px}
.rota-head h2{font-size:1.15rem;text-transform:uppercase;letter-spacing:.03em}
.rota{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:10px}
@media (max-width:900px){.rota{grid-template-columns:repeat(auto-fill,minmax(180px,1fr))}}
.no{display:flex;flex-direction:column;gap:8px;padding:14px;background:var(--panel);border:2px solid var(--line);border-radius:var(--r);text-decoration:none;color:var(--text);transition:border-color .15s,transform .15s}
.no:hover{border-color:var(--gold);transform:translateY(-2px)}
.no.atual{border-color:var(--gold);box-shadow:0 0 0 1px var(--gold),0 0 24px color-mix(in srgb,var(--gold) 25%,transparent)}
.no-id{font:700 .72rem/1 var(--f-mono);letter-spacing:.1em;color:var(--gold-b)}
.no-titulo{font:700 1.02rem/1.2 var(--f-display)}
.no-estado{font:700 .66rem/1 var(--f-mono);letter-spacing:.06em;text-transform:uppercase;color:var(--muted)}
.m-concluido .no-estado{color:var(--green)}
.segs{display:flex;gap:3px;height:10px;transform:skewX(-12deg)}
.seg{flex:1;background:var(--card);border-radius:1px}
.s-entregue.seg{background:var(--green)}
.s-construindo.seg{background:var(--gold)}
.s-proximo.seg{background:color-mix(in srgb,var(--cyan) 45%,var(--card))}
@media (prefers-reduced-motion:no-preference){.s-construindo.seg{animation:pulso 1.2s ease-in-out infinite}}
@keyframes pulso{50%{opacity:.45}}

/* blocos */
.bloco{margin-top:64px}
.eyebrow{font:700 .72rem/1 var(--f-mono);letter-spacing:.14em;text-transform:uppercase;color:var(--gold);margin:0 0 10px}
.bloco>h2{font-size:clamp(1.6rem,3.4vw,2.1rem);text-transform:uppercase;letter-spacing:-.01em;margin-bottom:24px}

/* partida */
.relogio{background:var(--panel);border:2px solid var(--border);border-radius:var(--r);padding:12px clamp(12px,3vw,28px);overflow-x:auto}
.relogio>*{min-width:820px}
.marcos{position:relative;height:40px;font-size:.78rem;color:var(--muted)}
.marco{position:absolute;bottom:4px;transform:translateX(-50%);white-space:nowrap}
.marcos-baixo .marco{top:4px;bottom:auto}
.marco b{font-family:var(--f-mono);color:var(--text)}
.marco:last-child{transform:translateX(-100%)}
.marcos-cima .marco:first-child{transform:translateX(-50%)}
.faixas{position:relative;height:44px}
.faixa{position:absolute;top:0;bottom:0;display:flex;align-items:center;padding-left:10px;overflow:hidden;
  clip-path:polygon(8px 0,100% 0,calc(100% - 8px) 100%,0 100%);font:700 .8rem/1 var(--f-display);text-transform:uppercase;letter-spacing:.04em;color:var(--bg)}
.faixa span{white-space:nowrap;overflow:hidden;text-overflow:ellipsis;line-height:1.5;padding-top:2px}
.f-gold{background:var(--gold)}.f-red{background:var(--red)}.f-purple{background:var(--purple)}
.f-red span,.f-purple span{color:#fff}
.tick{position:absolute;top:-6px;bottom:-6px;width:2px;background:var(--text);transform:translateX(-1px)}
.faixas-legenda,.regras{list-style:none;padding:0;margin:20px 0 0;display:grid;gap:8px}
.faixas-legenda li{display:flex;flex-wrap:wrap;gap:2px 8px;align-items:baseline}
.faixas-legenda .det{flex-basis:100%;padding-left:18px;color:var(--muted)}
.dot{display:inline-block;width:10px;height:10px;transform:skewX(-12deg)}
.regras{grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:12px}
.regras li{background:var(--panel);border-left:3px solid var(--gold);padding:12px 14px;border-radius:0 var(--r-sm) var(--r-sm) 0;font-size:.95rem}

/* pilares */
.pilares{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,300px),1fr));gap:20px;margin-top:28px}
.pilar{background:var(--panel);border:2px solid var(--line);border-radius:var(--r);padding:20px}
.pilar h3{font-size:1.15rem;text-transform:uppercase;color:var(--gold-b);margin-bottom:14px}
.pilar dl{margin:0;display:grid;gap:14px}
.pilar dt{font:700 1rem/1.3 var(--f-display)}
.papel{display:block;font:700 .68rem/1.4 var(--f-mono);letter-spacing:.06em;text-transform:uppercase;color:var(--cyan);margin-top:2px}
.pilar dd{margin:4px 0 0;color:var(--muted);font-size:.95rem}

/* capítulos */
.caps{display:grid;gap:28px}
.cap{display:grid;grid-template-columns:56px minmax(0,1fr);gap:16px}
.cap-trilho{position:relative;display:flex;justify-content:center}
.cap-trilho::before{content:"";position:absolute;top:56px;bottom:-28px;width:2px;background:var(--line)}
.cap:last-child .cap-trilho::before{display:none}
.m-concluido .cap-trilho::before{background:color-mix(in srgb,var(--green) 45%,transparent)}
.hex{width:52px;height:58px;display:grid;place-items:center;font:700 1.3rem/1 var(--f-display);
  clip-path:polygon(50% 0,100% 25%,100% 75%,50% 100%,0 75%,0 25%);background:var(--card);color:var(--muted)}
.m-concluido .hex{background:var(--green);color:var(--bg)}
.m-andamento .hex{background:var(--gold);color:var(--bg)}
.cap-corpo{background:var(--panel);border:2px solid var(--line);border-radius:var(--r);padding:clamp(18px,3vw,28px);display:grid;gap:20px;min-width:0}
.cap.atual .cap-corpo{border-color:var(--gold)}
.m-planejado .cap-corpo{background:color-mix(in srgb,var(--panel) 60%,var(--bg))}
.cap-meta{display:flex;flex-wrap:wrap;gap:10px;align-items:center;margin:0 0 10px}
.cap-head h3{font-size:clamp(1.5rem,3vw,2rem);text-transform:uppercase}
.pergunta{font:500 1.1rem/1.4 var(--f-display);color:var(--gold-b);margin:8px 0 0}
.cap-grid{display:grid;grid-template-columns:minmax(0,1.25fr) minmax(0,1fr);gap:28px;align-items:start}
.cap-grid.so-texto{grid-template-columns:minmax(0,1fr)}
@media (max-width:860px){.cap-grid{grid-template-columns:minmax(0,1fr)}}
.cap-texto{max-width:66ch}
.cap-texto p{margin:0 0 14px}
.aprendizado,.criterio{background:var(--card);border-radius:var(--r-sm);padding:12px 14px;font-size:.95rem}
.aprendizado .mono,.criterio .mono{display:block;margin-bottom:4px;color:var(--cyan)}
.cap-lado{display:grid;gap:16px;min-width:0}
.nums{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}
.num:last-child:nth-child(odd){grid-column:1/-1}
.num{background:var(--card);border-radius:var(--r-sm);padding:12px}
.num b{display:block;font:700 1.5rem/1.1 var(--f-mono);color:var(--gold-b);font-variant-numeric:tabular-nums}
.num span{font-size:.82rem;color:var(--muted)}
.cap-entregas{border-top:1px solid var(--line);padding-top:16px;display:grid;gap:12px}
.cap-entregas-head{display:flex;justify-content:space-between}
.itens{list-style:none;margin:0;padding:0;display:grid;grid-template-columns:repeat(auto-fill,minmax(min(100%,300px),1fr));gap:8px}
.it{display:flex;gap:10px;align-items:flex-start;font-size:.92rem;padding:8px 10px;background:color-mix(in srgb,var(--card) 60%,transparent);border-radius:var(--r-sm)}
.it-chip{flex:none;font:700 .62rem/1.6 var(--f-mono);letter-spacing:.06em;text-transform:uppercase;padding:1px 6px;border-radius:2px;background:var(--card);color:var(--muted);min-width:96px;text-align:center}
.it.s-entregue .it-chip{background:var(--green);color:var(--bg)}
.it.s-construindo .it-chip{background:var(--gold);color:var(--bg)}
.it.s-proximo .it-chip{background:color-mix(in srgb,var(--cyan) 30%,var(--card));color:var(--text)}
.it.s-entregue .it-txt{color:var(--text)}
.it.s-planejado .it-txt{color:var(--muted)}

/* figuras */
.fig{position:relative;margin:0;display:grid;gap:8px;min-width:0}
.fig-open{all:unset;cursor:zoom-in;display:block;border-radius:var(--r-sm);overflow:hidden;border:2px solid var(--line);background:var(--bg)}
.fig-open:focus-visible{outline:3px solid var(--gold-b);outline-offset:2px}
.fig img,.fig video{display:block;width:100%;height:auto;max-width:100%}
.fig .chip{position:absolute;top:10px;left:10px}
.fig figcaption{font-size:.85rem;color:var(--muted)}
.fig[data-tipo="conceito"] .fig-open{border-style:dashed;border-color:color-mix(in srgb,var(--purple) 55%,transparent)}
.galeria{display:grid;grid-template-columns:repeat(auto-fill,minmax(min(100%,260px),1fr));gap:20px;align-items:start}
.galeria .fig-open{aspect-ratio:4/3;max-width:100%}
.galeria .fig img{height:100%;object-fit:cover;object-position:top}
.aviso{margin:-8px 0 24px;max-width:70ch;color:var(--muted);border-left:3px solid var(--purple);padding-left:12px}

/* lightbox */
dialog.lb{border:0;padding:0;background:transparent;max-width:min(1200px,94vw);max-height:92vh}
dialog.lb::backdrop{background:color-mix(in srgb,var(--bg) 92%,transparent)}
dialog.lb img,dialog.lb video{display:block;max-width:100%;max-height:84vh;margin:auto;border-radius:var(--r-sm)}
dialog.lb p{color:var(--text);text-align:center;margin:10px 0 0}
dialog.lb button{position:fixed;top:16px;right:16px;font:700 .8rem/1 var(--f-mono);text-transform:uppercase;background:var(--gold);color:var(--bg);border:0;padding:10px 14px;border-radius:var(--r-sm);cursor:pointer}

/* rodapé */
.rodape{margin-top:72px;border-top:1px solid var(--line);background:color-mix(in srgb,var(--bg) 70%,#000)}
.rodape .wrap{display:flex;flex-wrap:wrap;justify-content:space-between;gap:12px 24px;padding-block:16px}
.rodape p{margin:0;font-size:.82rem;color:var(--muted)}
.status-bar{display:flex;flex-wrap:wrap;gap:6px 16px}
.status-bar span{font:700 .68rem/1.6 var(--f-mono);letter-spacing:.06em;text-transform:uppercase;color:var(--cyan)}
.status-bar span:first-child::before{content:"";display:inline-block;width:8px;height:8px;border-radius:50%;background:var(--green);margin-right:6px}
@media (prefers-reduced-motion:reduce){*{transition:none!important;animation:none!important;scroll-behavior:auto!important}}
`;

const JS = `
(function(){
  var d=document.getElementById('lb'); if(!d||!d.showModal) return;
  var box=document.getElementById('lb-midia'), leg=document.getElementById('lb-leg');
  document.addEventListener('click',function(e){
    var b=e.target.closest('.fig-open'); if(!b) return;
    var m=b.querySelector('img,video'); box.innerHTML='';
    var c=m.cloneNode(true); c.removeAttribute('loading'); box.appendChild(c);
    var cap=b.parentNode.querySelector('figcaption'); leg.textContent=cap?cap.textContent:'';
    d.showModal();
  });
  d.addEventListener('click',function(e){ if(e.target===d||e.target.id==='lb-fechar') d.close(); });
})();
`;

const marcaSvg = `<svg width="30" height="34" viewBox="0 0 30 34" aria-hidden="true"><path d="M15 1 29 9v16L15 33 1 25V9z" fill="none" stroke="${tokens.GOLD}" stroke-width="2.5"/><path d="M15 9v16M9 13l6 4 6-4" fill="none" stroke="${tokens.GOLD_BRIGHT}" stroke-width="2.5" stroke-linecap="round"/></svg>`;

const corpo = `
<header class="topo">
  <div class="wrap">
    <a class="marca" href="#inicio">${marcaSvg}<span><b>${esc(pj.nome)}</b><small>Diário de desenvolvimento</small></span></a>
    <nav class="nav" aria-label="Seções">
      <a href="#rota">Rota</a><a href="#partida">O jogo</a><a href="#jornada">Jornada</a><a href="#conceito">Conceito</a>
    </nav>
  </div>
</header>
<main class="wrap" id="inicio">
  <section class="capa" aria-labelledby="titulo">
    ${capa ? `<div class="capa-arte"><img src="${capa.src}" alt="${esc(capa.legenda)}"></div>` : ""}
    <div class="capa-txt">
      <h1 id="titulo">${esc(pj.nome)}${pj.nome_nota ? `<small>${esc(pj.nome_nota)}</small>` : ""}</h1>
      <p class="tagline">${esc(pj.tagline)}</p>
      ${(pj.pitch ?? []).map((p) => `<p>${esc(p)}</p>`).join("")}
      <div class="stack" aria-label="Tecnologias">${(pj.stack ?? []).map((s) => `<span>${esc(s)}</span>`).join("")}</div>
    </div>
    ${capa ? `<p class="capa-leg"><span class="chip tipo-${esc(capa.tipo)}">${TIPO_IMG[capa.tipo] ?? "Conceito"}</span>${esc(capa.legenda)}</p>` : ""}
  </section>

  <section class="rota-bloco" id="rota" aria-labelledby="rota-h">
    <div class="rota-head">
      <h2 id="rota-h">Rota até o playtest</h2>
      <span class="mono">${totalEntregues} de ${totalItens} entregas · agora: ${atual.id}</span>
    </div>
    <div class="rota">${rota}</div>
  </section>

  ${timeline}

  <section class="bloco" aria-labelledby="pilares-h">
    <p class="eyebrow">O que tem na arena</p>
    <h2 id="pilares-h">Heróis, monstros e itens</h2>
    <div class="pilares">${pilares}</div>
  </section>

  <section class="bloco" id="jornada" aria-labelledby="jornada-h">
    <p class="eyebrow">Capítulos</p>
    <h2 id="jornada-h">A jornada, marco a marco</h2>
    <div class="caps">${capitulos}</div>
  </section>

  ${galeria}
</main>
<footer class="rodape">
  <div class="wrap">
    <div class="status-bar"><span>Atualizado em ${dataBR}</span><span>Marco atual: ${atual.id}</span><span>Godot 4.7 · netfox · 30 Hz</span></div>
    <p>${(historia.creditos ?? []).map(esc).join(" ")}</p>
  </div>
</footer>
<dialog class="lb" id="lb" aria-label="Imagem ampliada"><button type="button" id="lb-fechar">Fechar</button><div id="lb-midia"></div><p id="lb-leg"></p></dialog>
`;

const head = `<title>Crônica do ${esc(pj.nome)}</title>
<meta name="description" content="${esc(pj.tagline)}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@700&family=Outfit:wght@400;500;600&family=Space+Grotesk:wght@500;600;700&display=swap">
<style>${CSS}</style>`;

const fragment = `${head}\n${corpo}\n<script>${JS}</script>\n`;
const full = `<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<!-- GERADO por tools/roadmap/build-roadmap.mjs — não edite à mão. Edite docs/roadmap/historia.json. -->
${head}
</head>
<body>
${corpo}
<script>${JS}</script>
</body>
</html>
`;

writeFileSync(outFull, full);
if (outFragment) writeFileSync(outFragment, fragment);
const size = Buffer.byteLength(full);
if (size > MAX_BYTES) warn(`página com ${(size / 1048576).toFixed(1)} MB: acima de 15 MB`);
console.log(`OK ${outFull} — ${(size / 1024).toFixed(0)} KB (imagens: ${(embeddedBytes / 1024).toFixed(0)} KB)`);
console.log(`MVPs: ${mvps.map((m) => `${m.id} ${m.entregues}/${m.total} ${m.estado}`).join(" | ")}`);
console.log(`Avisos: ${warnings.length}`);
