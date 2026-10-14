// Teste do gerador do roadmap público: dois marcos decimais seguidos (MVP2.5 e MVP2.6).
// Uso: node --test tools/roadmap
// Monta uma raiz falsa em temp (o gerador deriva a raiz da própria localização), então não toca o repositório.

import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync, copyFileSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const GERADOR = join(dirname(fileURLToPath(import.meta.url)), "build-roadmap.mjs");

// §2 propositalmente fora de ordem: o gerador tem de ordenar por valor (2 < 2.5 < 2.6 < 3).
const STATUS_MD = `## 2. Marcos

| Marco | Entrega | Módulos | Critério de pronto | Estado |
|---|---|---|---|---|
| MVP3 | Meta | backend | aceite | planejado |
| **MVP2.6** | Heróis 5 e 6 | game | aceite | cards criados |
| MVP2 | Partida | game | aceite | feito |
| MVP2.5 | Bloco visual | game | aceite | feito |

## 3. Fatias

| Fatia | MVP | Módulos | Descrição | Estado |
|---|---|---|---|---|
| F10 / SPEC-010 | MVP2 | game | Slice 2.1 — Partida | finalizado (#10) |
| F57 / SPEC-057 | MVP2.5 | game | Slice 2.5.8 — HUD moderna | done (#57) |
| [INFRA] | MVP2.6 | infra | Roadmap público aceita o marco \`MVP2.6\` | doing (#161) |
| F58 / SPEC-058 | MVP2.6 | game | Slice 2.6.1 — Ladina | todo (#58) |
| F59 / SPEC-059 | MVP2.6 | game | Slice 2.6.2 — Engenheiro | backlog (#59) |
| F21 / SPEC-021 | MVP3 | backend | Slice 3.1 — Backend | backlog (#21) |

## 4. Outro
`;

const PROPLAN_MD = `---
proplan: v1
updated: 2026-10-14
---
# Status

## Backlog

### [MVP2.6] Heróis 5 e 6 (#160)

- [MVP2.6][SPEC-059][F59] Engenheiro (#59)

### [MVP3] Meta (#76)

- [MVP3][SPEC-021][F21] Backend (#21)

## A fazer

- [MVP2.6][SPEC-058][F58] Ladina (#58)

## Finalizado

- [MVP2][SPEC-010][F10] Partida (#10, finalizado em: 2026-10-01)
- [MVP2.5][SPEC-057][F57] HUD moderna (#57, finalizado em: 2026-10-13)
`;

const TOKENS_MD = ["BG_SURFACE", "BG_PANEL", "BG_CARD", "GOLD", "GOLD_BRIGHT", "BLUE", "CYAN", "RED", "GREEN", "PURPLE", "TEXT", "TEXT_MUTED", "BORDER"]
  .map((k) => `| \`${k}\` | \`#112233\` |`).join("\n");

const capitulo = (titulo) => ({ titulo, pergunta: "?", periodo: "2026", narrativa: ["x"], numeros: [], aprendizado: "x", imagens: [] });
const HISTORIA = {
  projeto: { nome: "Jogo", tagline: "t" },
  capitulos: { MVP2: capitulo("Partida"), "MVP2.5": capitulo("Visual"), MVP3: capitulo("Meta") },
  rotulos_fatias: { F10: "Rótulo F10", F57: "Rótulo F57", F58: "Rótulo F58", F59: "Rótulo F59", F21: "Rótulo F21" },
};

function gerar() {
  const raiz = mkdtempSync(join(tmpdir(), "roadmap-test-"));
  try {
    const escreve = (rel, txt) => { mkdirSync(dirname(join(raiz, rel)), { recursive: true }); writeFileSync(join(raiz, rel), txt); };
    mkdirSync(join(raiz, "tools", "roadmap"), { recursive: true });
    copyFileSync(GERADOR, join(raiz, "tools", "roadmap", "build-roadmap.mjs"));
    escreve("docs/STATUS.md", STATUS_MD);
    escreve(".proplan/STATUS.md", PROPLAN_MD);
    escreve("docs/roadmap/historia.json", JSON.stringify(HISTORIA));
    escreve("docs/design-system/TOKENS.md", TOKENS_MD);
    const r = spawnSync(process.execPath, [join(raiz, "tools", "roadmap", "build-roadmap.mjs"), "--out", join(raiz, "out.html")], { encoding: "utf8" });
    return { ...r, html: r.status === 0 ? readFileSync(join(raiz, "out.html"), "utf8") : "" };
  } finally {
    rmSync(raiz, { recursive: true, force: true });
  }
}

test("dois marcos decimais: MVP2.6 entra entre MVP2.5 e MVP3, com F58 e F59 dentro", () => {
  const r = gerar();
  assert.equal(r.status, 0, r.stderr);

  const linha = r.stdout.split("\n").find((l) => l.startsWith("MVPs:"));
  const ids = [...linha.matchAll(/(MVP[\d.]+) \d+\/\d+/g)].map((m) => m[1]);
  assert.deepEqual(ids, ["MVP2", "MVP2.5", "MVP2.6", "MVP3"]);
  assert.match(linha, /MVP2\.5 1\/1 concluido/);
  assert.match(linha, /MVP2\.6 0\/2 planejado/); // F58 e F59 contam; o [INFRA] não

  for (const rotulo of ["Rótulo F57", "Rótulo F58", "Rótulo F59"]) assert.ok(r.html.includes(rotulo), rotulo);
  assert.ok(!r.html.includes("Roadmap público aceita"), "[INFRA] não aparece na página");
});

test("o único AVISO é o capítulo ausente do MVP2.6", () => {
  const avisos = gerar().stderr.split("\n").filter((l) => l.startsWith("AVISO"));
  assert.deepEqual(avisos, ["AVISO: MVP2.6: sem capítulo em historia.json"]);
});
