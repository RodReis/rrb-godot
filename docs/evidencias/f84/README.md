# F84 / SPEC-084 — Spike visual, parte 1: canto SO no estilo Eternal Return

Evidência de aceite da cena variante `game/scenes/arena/spike_f84.tscn` (issue #247). Todas as imagens têm a **oficial à esquerda** e a **variante à direita**, com a mesma câmera, a mesma seed (38) e o dia forçado.

## Como abrir

```powershell
& $env:GODOT_PATH --path game -- --offline --bot --arena=spike_f84
```

`--arena` é argumento de dev, fora do contrato do Launcher. Qualquer valor desconhecido abre a oficial.

## Frame time (aceite 3)

Medido com `tools/perf/frametime_probe.gd` em 1920x1080, RTX 5060, Vulkan. O herói fica parado no spawn A, com a câmera do jogo sobre a base SO, e cada medição dura 30 s. Foram 3 rodadas alternadas oficial × variante (APRENDIZADOS: só vale alternando). Os JSONs estão nesta pasta.

| Rodada | Oficial GPU média / p99 (ms) | Variante GPU média / p99 (ms) |
|---|---|---|
| 1 | 3,856 / 4,275 | 3,773 / 4,089 |
| 2 | 3,836 / 4,161 | 3,767 / 3,958 |
| 3 | 3,835 / 4,162 | 3,811 / 4,262 |
| **Média** | **3,842** | **3,784** |

A diferença (−0,06 ms) fica dentro do ruído: a arte nova não custa GPU mensurável nessa câmera. A CPU fica em 16,74 ms nos dois casos, preso nos 60 quadros por segundo.

## Capturas (aceite 4)

| Arquivo | O que mostra |
|---|---|
| `jogo_11u.webp` | câmera do jogo no spawn A, a 11 u |
| `close_portao.webp` | portão A visto de dentro da base |
| `close_fonte.webp` | fonte de cura A |
| `close_casa.webp` | casa atrás do spawn |
| `close_patio.webp` | sobrado e carroça do pátio |
| `close_torreao.webp` | torreão do canto |

Os closes foram feitos com `tools/perf/scenery_capture.gd --poses=f84`.

## O que mudou na variante

- O kit vem de `art/spike/f84/build_spike_f84.py`, feito no Blender por script: muralha, mureta interna, torre com telhado cônico, portão em arco com folhas novas, torreão, casa de pedra, sobrado e casinha de enxaimel, galpão, fonte octogonal, praça calçada com meio-fio e anel do spawn, e props (barril, caixote, estandarte, lanterna, moita, carroça e suporte de armas).
- As texturas são PBR CC0 do Poly Haven em 2K. A cor de vértice traz a sujeira perto do chão e a variação de cada bloco.
- Orçamento: a maior peça tem 1.432 triângulos, dentro do teto de 1.600 da SPEC §3.
- A cena é regerada pelo `tools/arena/build_spike_f84.gd` a partir da oficial. Ela sai como cópia gerada, não como cena herdada, porque o Godot 4.7 não deixa script criar herança. As 77 peças antigas do SO ficam escondidas, e a colisão, os marcadores e a base B são os da oficial. O teste `test_arena_spike_f84.gd` confere isso.
- A variante tem lightmap próprio (`spike_f84.lmbake`), gerado com `tools/bake-lightmap.ps1 -Scene res://scenes/arena/spike_f84.tscn -Builder tools\arena\build_spike_f84.gd`. Ela também ganhou 4 luzes de lanterna e manteve o `WorldEnvironment` da oficial.

## Achados para a decisão do PI (aceite 5)

- **O que o Blender por script entrega bem:** volumes com proporção real, telhado de telha, calçamento e cantaria com PBR. Na câmera do jogo a base passa a ler como uma praça medieval coesa.
- **Onde fica abaixo da referência:** formas orgânicas e detalhe fino. As moitas ficam com aspecto de bolha, as floreiras com aspecto de brinquedo, o enxaimel fica chapado e o feno é uma caixa. Na sombra, a pedra fica marrom-escura com o sol atual.
- **Estilo misto:** o Cavaleiro KayKit low-poly destoa do cenário, como a SPEC §6 já previa. O F93 fecha essa comparação.
