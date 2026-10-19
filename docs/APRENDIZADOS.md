# APRENDIZADOS.md — Armadilhas já pagas

**Leitura obrigatória do Code no passo 1 de todo card.** Curto por desenho.

## Protocolo

- Fonte: seção **Aprendizado** do comentário de encerramento de cada card (skill `fechar-card`). Só entra com fonte verificável (doc oficial, commit, log, comando).
- Consolidação: o Cowork promove para cá no fecho de cada MVP. Entre fechos, o Code pode propor linha por PR de docs.
- **Teto: 30 linhas na seção "Vigentes".** Passou do teto, a mais antiga ou menos recorrente desce para "Arquivo" — ou vira regra em `CLAUDE.md`/`CONVENTION.md` (promoção) e sai daqui.
- Formato: `- [módulo] frase única com a armadilha e o que fazer — fonte`.

## Vigentes

- [game] Clone novo não tem `.godot/`; rode `--import` headless antes de testes, senão o runner não carrega — engine-reference.
- [game] Lambda em GDScript captura local **por valor**; para sinal que marca flag, use Dictionary/objeto — engine-reference.
- [shared] Sem `tools/link-shared.ps1` o projeto abre com erros de `res://shared` — comportamento esperado, não bug — ADR-0003.
- [game] O `sanitize` do netfox só confere o dono do input, não o valor; o servidor valida faixa/NaN (`InputRules`) — `addons/netfox/properties/property-snapshot.gd` (#4).
- [game] netfox 1.35.3 inicia o `NetworkTime` pelo `NetworkEvents`; chamar `NetworkTime.start()` à mão dá `ERR_ALREADY_IN_USE` — `network-events.gd:82` (#4).
- [game] GUT 9.7.1 sai com 0 quando não há teste **e** quando um script de teste não compila (`Nothing was run`); `tools/test.ps1` trata isso, não confie só no exit code — PR #10 (#9).
- [game] Cache `game/.godot` gerado antes de copiar `addons/` esconde os plugins; apague `.godot` e reabra — sessão do PI (#2).
- [game] Godot não grava no `project.godot` valor igual ao padrão; ausência de chave ≠ não configurado — commit `9d69a6c` (#2).
- [game] Com perda, a RPC de estado pode chegar antes do spawn retransmitido (`Node not found .../RollbackSynchronizer`) e é descartada — F20 precisa de spawn confiável antes de estado (#6).
- [infra] `tc netem` só numa direção desalinha o relógio do netfox (ida e volta simétricas); `NETEM_DELAY_MS` é o RTT total dividido entre `eth0` e `ifb0` — ADR-0001 (#7).
- [infra] Sob 5 % de perda com jitter, diff states sem referência são descartados (`DiffHistoryEncoder: Reference tick missing`) e o remoto congela; candidatos: `full_state_interval`, `diff_ack_interval`, desligar diff states — ADR-0001, vigiar no F20 (#7).
- [docs] Paleta do DV: `BLUE`/`RED`/`PURPLE` não passam contraste como texto pequeno; use fundo/borda — `design-system/TOKENS.md` (medido 2026-10-08).
- [game] Teste GUT que dá `free()` ou `remove_child` num `Hero` falha por sinais do netfox ("Unexpected Errors", `Attempt to disconnect a nonexistent connection`); use ids/posições distintas, deixe o autofree e, se precisar tirar da árvore, chame `_exit_tree()` direto — `test_hero_controle_alcance`, `test_cover_silhouette` (#194, #200).
- [game] Nó de VFX/HUD visual não pode existir no servidor headless; instancie só sob `VfxSpawner.wanted()` — `test_vfx_headless` falhou com `Hud/TargetRing` (#194).
- [game] `TickInterpolator.teleport()` (netfox 1.35.3) grava o estado ATUAL do node como destino; chamado no `_process` (transform já interpolado) grava a posição antiga, inclusive no servidor. Teleporte só no laço de ticks (`after_tick_loop`); herói de rollback, em `NetworkRollback.after_process_tick` — `addons/netfox/tick-interpolator.gd:84` (#216, #200).
- [game] `Monster.receive_hit` tira o HP na hora (o herói só no tick+1): cálculo que lê HP do monstro tem de rodar antes do `_hit` — `game/scripts/ai/monster.gd` (#203).
- [game] `Vector2` guarda float32: comparar valor vindo do estado (`slow_pct`) com o `double` do `.tres` falha no `>=`; use epsilon (`SLOW_EPSILON`) — teste `test_raiz_dentro_do_pantano...` (#202).
- [game] `Node3D` filho de um `Node` simples não herda transform nem `visible` do avô: serve para pendurar entidades independentes na cena do herói (`Servants`, que não somem com o herói no mato) — `game/scenes/heroes/occultist.tscn` (#216).
- [game] Shader que escreve `ALPHA` em qualquer ramo vai para o pipeline transparente; dê shader próprio ao que precisa de alpha (a moita) em vez de mexer no `triplanar_pbr` — docs Godot 4.7 `spatial_shader.rst` (#200).
- [game] Script de `SceneTree` (`-s`) compila antes dos autoloads: classe que usa `NetworkTime` dá `Identifier not found` — `godot --path game -s tools/ui/render_loading.gd` (#196).
- [game] A carga síncrona do `ShaderWarmup` (~1 s) bloqueia o 1º quadro; a tela de loading só aparece com `await RenderingServer.frame_post_draw` antes dela — `main.gd`, log `[warmup] 274 instancias aquecidas em 968 ms` (#196).
- [shared] Godot aberto no projeto reescreve `.tres` (uid, ordem de propriedades) e derruba campo recém-adicionado; feche o editor ou refaça a edição antes de commitar — `git diff shared/data/heroes/knight.tres` (#199).
- [shared] `CatalogService.load_all` carrega todo `.tres` de `shared/data/heroes/` como `HeroData`; Resource de outro tipo ali quebra os testes do launcher (por isso `servants/` fica fora) — `launcher/scripts/services/catalog_service.gd` (#216).
- [infra] `gdlint` limita 20 métodos públicos por classe (script e teste GUT); no teste, `# gdlint: ignore=max-public-methods` na 1ª linha; no script, tire leitores da classe — `shared/test/test_data_catalog.gd:1` (#194, #195, #198).
- [infra] `tools/screenshot.ps1` recorta a área da tela: com outra janela por cima, a captura sai com ela; para evidência use `tools/perf/frametime_probe.gd --shot=` (só o viewport) — #200, #215.
- [infra] Editar `*.gd` com `tools/soak.ps1` rodando mistura versões nas partidas seguintes; pare o soak e reinicie — `bot_input.gd` alterado no meio da rodada (#194).
- [infra] VM do Docker Desktop dividida com outras pilhas trava o servidor (`Game stalled` até 13,5 s; `docker pause` não libera RAM; travada idêntica nos 2 clientes é do host) e o stdout do container só descarrega tarde (`net-measure.ps1` esperando `escutando` estoura os 2 min); meça rede só com a VM folgada — `wsl -d docker-desktop -- free -m` (#215, #214, #202).
- [infra] `.import` de glb com `use_external` editado antes de o `.tres` existir importa sem o remap e não reimporta sozinho; apague `game/.godot/imported/<glb>-*` e rode `--import` — #201.
- [infra] Frame time só se mede com rodadas alternadas base × PR: a mesma build deu +1,4 e +0,009 ms em estados diferentes da cena — `docs/evidencias/f73/frame-time.md` (#201).
- [art] `/art/` está no `.gitignore`: arquivo novo entra só com `git add -f`; `art/heroes/equipment/build_equipment.py` reexporta todas as peças com bytes diferentes — só as do card entram, o resto volta com `git checkout` — `git check-ignore -v` (#203, #214).

## Arquivo

Desceram de "Vigentes" por teto ou por terem virado regra em `CLAUDE.md`/`ARCHITECTURE-GAME.md`/ADR (2026-10-19).

- [game] O `.exe` principal do Godot não imprime no terminal; use o `*_console.exe` para ver saída e crash — `CLAUDE.md` Comandos.
- [game] PowerShell 5.1 trata stderr de executável nativo como exceção com `$ErrorActionPreference='Stop'`; use `'Continue'` ao chamar o Godot — `CLAUDE.md`.
- [game] godot-mcp perde a saída quando o jogo crasha; rode pelo terminal para ver o erro — `README.md`.
- [game] `rg --type gdscript` é erro; use `--glob "*.gd"` — `docs/engine-reference/godot/current-best-practices.md`.
- [game] Efeito sobre outro node via `NetworkRollback.mutate` se perde na ressimulação (netfox 1.35.3); use ledger fora do estado e aplique no `_rollback_tick` do alvo — **promovido** a regra em `CLAUDE.md` e `ARCHITECTURE-GAME.md` §3.2 (#5).
- [game] `enable_prediction=false`: node sem input no tick não é simulado nem transmitido; bot e desconectado precisam de input — **promovido** a `ARCHITECTURE-GAME.md` §3.2/§6 (#5).
- [game] Cliente que trava ~1,4 s no sync inicial (shaders frios) pode ficar com rollback preso (`past the history limit of 64`); visto 1× (#4) — **promovido** a critério de aceite de toda fatia visual: warm-up de shaders antes do `connect` + 3/3 conexões a 100 ms (ADR-0006 item 7).
- [infra] Godot headless em debian-slim imprime `Unable to load fontconfig` no `--import`; inofensivo — F5 (#6).
- [infra] `docker images` no Docker Desktop (containerd) soma camadas comprimidas e descompactadas; meça por `docker history` ou `docker save` — PR #14 (#6).
- [game] `Label3D` com fonte padrão é ilegível a ~15 m; `font_size` alto + `pixel_size` 0.01 — commit `23d3fef` (#5).
