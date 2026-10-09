# SPEC-034 — Arena: pilares da cratera e mato alto com assets do Blender

**Fatia:** F34 / SPEC-034 (MVP1, Slice 1.10) · **Issue:** #38 · **Status:** aprovada pelo PI em 2026-10-09 ("sim" ao card de integração)
**Fontes:** ADR-0005 (Blender no pipeline) · SPEC-007 §2 (pilares, mato) · PRD §11 (alinhamento) · `CLAUDE.md` "Assets 3D"
**Depende de:** `[INFRA]` #34 (`.gitattributes`, `.gitignore`, import de `.blend` desligado) e F7 (#19, arena em `tools/arena/build_arena.gd`).

## 1. Objetivo

Trocar os placeholders geométricos do F7 pelos primeiros assets próprios feitos no Blender, **sem mudar gameplay**: só a malha visual muda; colisão, `Area3D` do mato, posições e medidas continuam as da SPEC-007, nas constantes do builder.

| Placeholder no F7 (`build_arena.gd`) | Asset novo | Instâncias |
|---|---|---|
| `CylinderMesh` r 1,4 × h 3,0 em `_build_crater()` | `shared/assets/rrb/arena/crater_pillar.glb` (84 tri, ~3,3 × 3,0 u, base em y = 0) | 8 pilares da cratera |
| `BoxMesh` 4 × 1,2 × 4 em `_tall_grass()` (moitas das bases) | `shared/assets/rrb/arena/tall_grass_4x4.glb` (294 tri) | `YARD_GRASS` (2 por base) |
| `BoxMesh` 4 × 1,2 × 3 em `_tall_grass()` (anel central) | `shared/assets/rrb/arena/tall_grass_4x3.glb` (210 tri) | `CENTER_GRASS` (2) |

Fonte: `art/arena/crater_props.blend` (cena `crater_props`; prévia `art/arena/preview_crater_props.png`). Os três `.glb` e a fonte já existem no disco do PI, **fora do git** — entram no PR desta fatia.

## 2. Regras

- **Só visual.** `CylinderShape3D` dos pilares (r 1,4, h 3,0), `BoxShape3D`/`Area3D` do mato (grupo `tall_grass`) e camadas de colisão ficam exatamente como no F7. Os `.glb` não trazem colisão (sem sufixos `-col`).
- **Origem:** os três assets têm origem no centro da base (y = 0). O pilar é instanciado no chão (não em `PILLAR_HEIGHT / 2` como o cilindro); o mato no `Area3D`, sem o deslocamento `GRASS_HEIGHT / 2` da caixa.
- **Orientação:** mato com a mesma `basis` que o builder já passa para `_tall_grass()` (eixo X do asset = `size.x`, eixo Z = `size.y`). Pilar com rotação fixa por instância (ex.: yaw = azimute do pilar), **sem RNG** — arena idêntica no servidor e no cliente (SPEC-007 §6, item 7).
- **Instância por cena empacotada:** o builder passa a instanciar os `.glb` como faz com o KayKit (`_instance`), em vez de criar `CylinderMesh`/`BoxMesh`. Constantes de cor `STONE`/`GRASS` saem se ficarem sem uso.
- **Cores:** vêm do atlas do KayKit embutido no `.glb`; nenhum material sobrescrito na cena.
- **Alinhamento:** os três assets entram na cena de alinhamento (PRD §11) quando ela existir (F31); se F31 já estiver integrado, entram nesta fatia.

## 3. Critério de aceite

1. `arena.tscn` regenerada pelo builder; nenhum `CylinderMesh`/`BoxMesh` restante para pilar e mato (grep na cena).
2. Testes do F7 continuam verdes sem alteração de expectativa: contagem de marcadores, simetria, flecha de 0,3 u bloqueada entre pilares e livre nas 4 entradas, rio só pelas pontes.
3. GUT novo: os 8 pilares e as 6 moitas têm instância do `.glb` correto; o AABB visual de cada pilar contém o cilindro de colisão (r 1,4) — nada de parede invisível.
4. CI verde em runner sem Blender (link do run na PR).
5. Verificação visual do PI: o Code sobe 2 clientes e pede ao PI para olhar cratera e moitas.

## 4. Fora desta spec

Regra de esconder no mato (F32, MVP2). Cor da grama dos hexágonos (decisão visual pendente do PI). Luz/`WorldEnvironment` (F31). Qualquer outro asset novo.
