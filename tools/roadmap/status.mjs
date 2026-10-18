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

/**
 * @param {string} statusMd docs/STATUS.md
 * @param {string} proplanMd .proplan/STATUS.md ("" se ausente)
 * @param {(m: string) => void} warn
 * @returns {{ mvps: object[], fatias: object[], proplanUpdated: string|null }}
 */
export function parseStatus(statusMd, proplanMd, warn = () => {}) {
  const mvps = [];
  for (const l of section(statusMd, /^## 2\./)) {
    const m = l.match(/^\|\s*\*{0,2}(MVP\d+(?:\.\d+)?)\*{0,2}\s*\|/);
    if (!m) continue;
    const c = cells(l);
    mvps.push({ id: m[1], entrega: c[1], criterio: c[3] });
  }
  if (!mvps.length) throw new Error("docs/STATUS.md §2: nenhuma linha de MVP encontrada");
  mvps.sort((a, b) => Number(a.id.slice(3)) - Number(b.id.slice(3))); // por valor: MVP2.5 entre MVP2 e MVP3

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
