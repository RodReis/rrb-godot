# SPEC-049 — Ciclo dia/noite sincronizado com o relógio da partida

**Fatia:** F49 / SPEC-049 (MVP2, Slice 2.15) · **Issue:** #122 · **Status:** decidida pelo PI em 2026-10-11 (pop-up) · **Entrega:** `finalizado` em 2026-10-11 (#122)
**ADR:** ADR-0010 — supera o clima fixo "sombrio" aceito no F40 e muda o conteúdo do bake do `LightmapGI` (ADR-0006 item 3)
**Fontes:** ADR-0006 · ADR-0010 · `match_pacing.tres` (`max_match_duration` = 600 s) · `game/scripts/match/match_clock.gd` · `game/scenes/arena/ilha_arcana.tscn` (`Sun`, `WorldEnvironment`, `LightmapGI`) · `shared/shaders/abyss_sky.gdshader` · `game/scripts/world/arena_environment.gd`
**Escopo:** só cliente (visual). Regras, visão da neblina (12 u), mato alto e bot não mudam.

## 1. Decisões do PI (2026-10-11)

1. A luz transita ao longo dos 10 min: começa de dia e termina de noite, **ou** o contrário — sorteado.
2. **Dia claro de verdade:** céu azul, sol alto, sombras fortes. **Noite** = o visual atual aceito no F40 (céu cósmico, nebulosa, estrelas).
3. `LightmapGI` **rebakeado sem o sol**: indireto só de céu/emissivos; o sol é 100% dinâmico.
4. Sentido sorteado **50/50 pela seed da partida**; argumento `--daynight day|night` força o início (teste).

## 2. Comportamento

- **Progresso** `p = clamp(elapsed / max_match_duration, 0, 1)` com `elapsed` do `MatchClock` (tempo da partida, não do processo). Seleção de heróis: `p = 0`. Partida que termina antes dos 10:00 (kills) congela onde estava. Morte súbita/colapso após 600 s: `p = 1`.
- **Sentido:** `day_to_night` ou `night_to_day`; `t` = `p` ou `1 − p` sobre uma única curva dia (0) → noite (1).
- **Curva:** pontos-chave num Resource `DayNightProfile` (`shared/data/visual/day_night.tres`): dia (0), entardecer (0,5, luz quente e baixa), noite (1). Interpolação suave entre eles.
- **O que varia com `t`:** direção e elevação do `Sun` (alto ao meio-dia, abaixo do horizonte à noite, com a lua/luz fria assumindo), cor e energia do `Sun`; cor/energia da luz ambiente; cor/densidade do fog volumétrico; céu (§3); energia de emissão de magma, cristais e rio de mana (mais fortes à noite); exposição/tonemap se necessário.
- **Sincronia:** os dois clientes leem o mesmo `elapsed` do relógio e o mesmo sentido → mesma luz, sem RPC por quadro. O sentido vem da seed: se a seed não chega ao cliente hoje, vai como um campo no RPC confiável de início de partida já existente (o Code decide onde).
- **Servidor headless:** nada roda.
- **Legibilidade:** à noite heróis, monstros, baús e projéteis continuam legíveis na câmera do jogo (outline do F39 + piso de luz ambiente no perfil). Critério do PI na verificação.

## 3. Céu

- Estado **noite** = `abyss_sky` atual, sem regressão visual (comparar screenshot com o do F40 no roadmap).
- Estado **dia** = novo: gradiente azul no hemisfério superior, disco do sol na direção do `Sun`, névoa clara no horizonte; o abismo abaixo da ilha continua, clareado.
- Um único shader com parâmetro de mistura (`day_amount`), ou dois materiais misturados — decisão do Code; a troca é contínua, sem salto.

## 4. Lightmap

- `Sun.light_bake_mode` desligado; rebake com o indireto do céu neutro + emissivos (passo de build do ADR-0006). Sombras do sol dinâmicas (`shadow_enabled` já ligado); `directional_shadow_max_distance` revisto para o sol alto.
- O `ReflectionProbe` é revisto: `UPDATE_ONCE` com céu de dia ficaria errado à noite — o Code escolhe entre atualizar em degraus de `t` ou reduzir a contribuição.

## 5. Implementação

- `game/scripts/core/day_night_rules.gd`: funções puras (`progress`, `t` por sentido, sentido pela seed) com GUT.
- `game/scripts/world/day_night.gd` (node só cliente na arena): lê o relógio, amostra o perfil, aplica no `Sun`, `Environment` (cópia do `ArenaEnvironment`) e materiais. Sem alocação em `_process`; atualização no máximo a cada quadro.
- `shared/core/launch_args.gd`: `--daynight day|night` (opcional; ausente = sorteio). Argumento de teste, fora do contrato Launcher ↔ Game (ADR-0010).
- `shader_warmup.gd`: aquecer os dois estados do céu antes do `connect` (ADR-0006 item 7).

## 6. Critério de aceite

1. GUT: `progress` (0, meio, fim, além de 600 s, antes da partida), `t` nos dois sentidos, sorteio pela seed (mesma seed → mesmo sentido; distribuição ~50/50 em 1.000 seeds), parse de `--daynight`.
2. 2 clientes contra servidor local: mesma luz nos dois (screenshots no mesmo segundo); sem `past the history limit`.
3. Frame time dentro do orçamento do ADR-0006 item 7 contra o baseline do F38, nos dois extremos.
4. Lint e CI verdes. Verificação visual do PI: `--daynight day` e `--daynight night` no início, meio (5:00) e fim (10:00) + vídeo curto acelerado no roadmap.

## 7. Fora desta spec

Visão reduzida à noite ou qualquer efeito de jogo; nuvens dinâmicas, chuva, clima; tochas/luzes pontuais novas; opção de ligar/desligar o ciclo nas configurações; ciclo no Launcher (F33 renderiza um estado fixo).
