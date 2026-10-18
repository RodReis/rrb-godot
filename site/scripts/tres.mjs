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
