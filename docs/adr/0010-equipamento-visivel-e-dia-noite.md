# ADR-0010 — Equipamento visível no herói e ciclo dia/noite pelo relógio da partida

**Status:** aceito — 2026-10-11
**Decisor:** Rodrigo Reis (PI)
**Supera parcialmente:** ADR-0006 item 3 (conteúdo do bake do `LightmapGI`: passa a excluir o sol) e item 4 (personagens dos packs CC0 "como vêm": passam a receber peças próprias presas a ossos). Supera o clima fixo "realista e sombrio" aceito no F40 — a noite continua sendo aquele visual; o dia é estado novo.
**Relacionados:** SPEC-047 · SPEC-048 · SPEC-049 · ADR-0005 · GDB §6

## Contexto

- O PI pediu (2026-10-11): ver armas e armaduras no herói e no baú; e uma transição de luz ao longo dos 10 min da partida, sorteando começar de dia ou de noite.
- O KayKit Adventurers gratuito não tem peças de armadura. O F40 foi aceito com céu cósmico sem sol e o ADR-0006 fixou `LightmapGI` bakeado com o sol da noite.

## Decisão

1. **Armas e armaduras visíveis**, modeladas no Blender (ADR-0005), peças rígidas presas a ossos por `BoneAttachment3D`; raridade por acabamento sobre a mesma forma. Estilo de personagem (sem bevel). Só cliente.
2. **Ciclo dia/noite** como função pura do tempo da partida (`MatchClock`), sentido sorteado 50/50 pela seed; dia claro (céu azul, sol alto); noite = visual do F40. Só cliente; nenhum efeito de jogo.
3. **Lightmap sem o sol:** rebake com indireto do céu neutro e emissivos; sol 100% dinâmico.
4. **`--daynight day|night`** é argumento de teste do Game, fora do contrato Launcher ↔ Game (`ARCHITECTURE-LAUNCHER.md` §5) — o Launcher não o envia.

## Alternativas rejeitadas

| Alternativa | Motivo |
|---|---|
| Armadura só por ícone | PI escolheu armadura modelada agora |
| Peças com skinning no rig | custo maior; rígidas bastam na câmera de 14 u |
| Dia = crepúsculo mantendo o céu cósmico | PI quer dia claro de verdade |
| Manter o bake com sol | de dia o indireto ficaria o da noite |
| Dois bakes misturados | Godot não mistura dois `LightmapGI` nativamente |

## Consequências

- 22 malhas novas + ícones (SPEC-048); o maior custo de arte do MVP2.
- Frame time: sombras dinâmicas do sol alto e o céu misturado entram no orçamento do ADR-0006 item 7.
- F33 (Arena & Mapa, MVP3) renderiza um estado fixo da arena — escolher dia ou noite é da spec do F33.
