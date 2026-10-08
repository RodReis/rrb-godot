# Godot Engine — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Godot 4.7.2 |
| **Installed at pin time** | 4.7.2-stable (Windows, `C:\Desenv\engine\godot`) |
| **Release Date** | 4.7: 2026 (4.6: January 2026) |
| **Project Pinned** | 2026-10-08 |
| **Last Docs Verified** | 2026-10-08 (4.7 delta); 2026-02-12 (4.4–4.6) |
| **LLM Knowledge Cutoff** | May 2025 |

## Knowledge Gap Warning

The LLM's training data likely covers Godot up to ~4.3. Versions 4.4, 4.5,
and 4.6 introduced significant changes that the model does NOT know about.
Always cross-reference this directory before suggesting Godot API calls.

## Installed-Version Gap Warning

The warning above is one-directional — it covers the **model** knowing less than
this pin. The reverse gap is real and `/setup-engine` §3 creates it deliberately
("pin the newer one and upgrade later"): this reference can sit **ahead of the
installed editor**, and an agent citing it correctly then emits APIs that do not
compile locally. **Check `Installed at pin time` above before trusting a
version-qualified claim** — `NOT DETERMINED` means the gap is unknown, not absent.

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 4.4 | ~Mid 2025 | MEDIUM | Jolt physics option, FileAccess return types, shader texture type changes |
| 4.5 | ~Late 2025 | HIGH | Accessibility (AccessKit), variadic args, @abstract, shader baker, SMAA |
| 4.6 | Jan 2026 | HIGH | Jolt default, glow rework, D3D12 default on Windows, IK restored |
| 4.7 | 2026 | LOW–MEDIUM | Input device IDs, typed-return inheritance, Jolt WorldBoundary sign, stretch defaults |

## Verified Sources

- Official docs: https://docs.godotengine.org/en/stable/
- 4.6→4.7 migration: https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.7.html
- 4.5→4.6 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html
- 4.4→4.5 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html
- Changelog: https://github.com/godotengine/godot/blob/master/CHANGELOG.md
- Release notes: https://godotengine.org/releases/4.6/

## Fonte desta cópia

Base: `docs/engine-reference/godot/` de [Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)
(MIT, commit `be8993b`), verificada até 4.6. O delta 4.6→4.7 foi acrescentado em 2026-10-08 a partir do guia oficial
de migração. Os módulos (`modules/*.md`) ainda dizem "Engine: Godot 4.6" — o conteúdo vale para 4.7 salvo o que
está em `breaking-changes.md` § 4.6 → 4.7.
