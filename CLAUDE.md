# rrb-godot — instruções para o Claude

Você atua como **engenheiro sênior de Godot 4 / GDScript** neste repositório. Responda sempre em **pt-BR**.

## Papéis

**PI — Rodrigo Reis.** Decide escopo, prioridade e trade-off. Responde dúvidas, aprova specs e aceita entregas. Não executa o fluxo: não cria issue, não commita, não abre PR, não faz merge. O aceite é só dele.

**Cowork — planejamento.** Especifica e mantém `CLAUDE.md`, `docs/prd/mvp/spec/`, `docs/prd/`, `docs/adr/` e o Índice Fatia ↔ SPEC do `docs/STATUS.md`. Antes de fechar uma spec, apresenta ao PI as dúvidas abertas em perguntas objetivas (pop-up); só cria a issue com todas resolvidas, para evitar retrabalho. Escreve documento direto na `main`, sem PR. Cria e mantém a issue-pai de cada MVP, vincula cada card do MVP como sub-issue nativa do GitHub, cria as issues no board na ordem de implementação e mantém os próximos 5 cards em `proplan:todo`. Nunca escreve código — implementação é exclusiva do Code.

**Code — Claude Code, developer. Você.** Pega a issue e coloca para `proplan:doing`, implementa a partir das issues, na ordem do board. Codifica, revisa e testa antes do commit; entrega por PR com CI verde e mergeia ele mesmo. Atualiza a documentação de entrega ao final de cada card, atualiza a issue com a skill `fechar-card` no mesmo PR. Cria a própria issue `[FIX]`. Não cria issue de fatia nem `[INFRA]` — isso é do Cowork. Pode criticar arquitetura e spec; não discute escopo e não descarta escopo, vai para backlog.

## Unidade de trabalho: card = fatia

- Fatia é a Slice N.M do PRD (`docs/prd/mvp/MVP-*.md`). Cada fatia recebe um número `F<n>` e um número `SPEC-<nnn>` **iguais**, alocados uma única vez pelo Cowork no Índice Fatia ↔ SPEC do `docs/STATUS.md` (fonte única do par MVP ↔ SPEC ↔ Fatia). Número nunca é reaproveitado.
- Uma spec gera exatamente uma fatia. Partir uma fatia é decisão do PI e gera spec nova com número novo — não sufixo.
- Uma issue por fatia, **nunca por passo**. Os passos vivem em `docs/DEVELOPMENT.md`.
- Plano de gate/homologação de MVP não é fatia: vira card `[GATE]`, sem `F` e sem `SPEC`.

### Título da issue
- Ler o conforme `docs/GITHUB.md`.

## Testes e CI
- Para CI remoto, usar `gh pr checks <n>` ou `gh pr checks <n> --watch`. Não confiar em silêncio de
  watcher, print antigo, aba aberta ou status lembrado.
- Ler o conforme `docs/CI-PR.md`.

## Projeto

- MOBA 3D de 2 tempos (preparação 5 min → confronto com zona), multiplayer com **servidor autoritativo**.
- Fonte de verdade de escopo: `docs/prd/PRD.md`. Layout da arena: `docs/prd/mvp/spec/SPEC-046.md` (ADR-0009; em vale sem abismo, ADR-0012). Números e fórmulas: `docs/prd/GDB.md` (vence o PRD — ADR-0004). Telas: `docs/prd/DESIGN-VISUAL-LAUNCHER.md`. Benchmark: `docs/prd/REFER.md`. Planos e specs de trabalho: `docs/superpowers/`. Decisões: `docs/adr/` (índice em `docs/DECISIONS.md`).
- Marco atual: **MVP3 — Meta + deploy** (issue-pai #76): restam **F28** (#82, deploy no VPS do PI) e o **[GATE] #87**. MVP0 a MVP2.8 entregues (F66–F78 `finalizado`); próximo, **MVP4 — Playtest**, e depois **MVP5 — Early Access** (ADR-0024 a ADR-0028). MVP-n = marco M-n do PRD. Estado em `docs/STATUS.md`, ordem de execução em `docs/DEVELOPMENT.md`.
- **10 heróis jogáveis:** Cavaleiro, Arqueiro, Bárbaro, Bruxo de Fogo, Ladina, Engenheiro, Protetor da Selva, Berserker, Paladino Radiante e Ocultista (`shared/data/heroes/`, números no GDB §4).
- Stack: **Godot 4.7.2** (Forward+ **only** — ADR-0006), GDScript, **netfox** (rollback/predição), **GUT** (testes), Docker (game server headless), **NestJS 11 + Postgres** (backend, MVP3; Node ≥ 24, pnpm), **Blender 5.2 LTS + Blender MCP** (assets 3D, ADR-0005), **React 19 + Vite + TypeScript** (só o site público, ADR-0017). Versões fixadas: netfox 1.35.3, GUT 9.7.1. Windows + PowerShell.
- **Dois módulos independentes** (ADR-0002), mesmo monorepo, sem importar nada um do outro:
  - **Game** (`game/`): partida — cliente + servidor dedicado. Seleção de heróis, HUDs, fim de partida. `docs/ARCHITECTURE-GAME.md`.
  - **Launcher** (`launcher/` + `backend/`): fora da partida — login, lobby, fila, histórico, bestiário, forja, arena & mapa, configurações; backend de auth/fila/orquestração. `docs/ARCHITECTURE-LAUNCHER.md`.
  - Comum: `shared/` (Resources `.tres`, regras puras, Theme, assets), montado nos dois por junction (`tools/link-shared.ps1`, ADR-0003). Contrato Launcher ↔ Game: processo + argumentos + `settings.cfg` (`ARCHITECTURE-LAUNCHER.md` §5). Mudar o contrato exige ADR.
  - **Site público** (`site/`, ADR-0017, emenda ao ADR-0002): landing "Loot Start" em React + Vite no GitHub Pages, sem relação de código com Game, Launcher ou Backend; lê `shared/data/heroes`, `docs/roadmap/` e `docs/STATUS.md` em build. `docs/SITE.md`. "Loot Start" é o nome do jogo inteiro desde o F82 (ADR-0022): janelas, Launcher, splash, `LootStart.exe`; repo, pastas e código seguem `rrb-*`.
- Estrutura (`shared/` entra nos dois projetos por junction — `tools/link-shared.ps1`):

```
game/                 projeto Godot A — partida (cliente + servidor dedicado)
  scripts/core/       regras puras de partida (arco, mira, zona, vitória) — sem nodes, 100% testadas
  scripts/net/        nodes de rede (heróis, input, projéteis) — usam core e shared/core
  scripts/match/      MatchController (FSM), relógio, zona, kills
  scripts/ai/         bot (BotInput), monstros e Servos do Vazio
  scripts/world/      arena: baús, portões, zona, fonte, neblina, dia/noite, vegetação
  scripts/vfx/        efeitos visuais — só cliente, nada no servidor headless
  scripts/items/      inventário e aplicação de atributos
  scripts/ui/         HUDs, pick, fim de partida — só consomem sinais
  scripts/server/     integração do servidor dedicado com o backend (auth, heartbeat, resultado)
  scripts/client/     warm-up de shaders e lineup de equipamento
  test/unit/          testes GUT
  addons/             terceiros (netfox, gut) — NUNCA editar
  shared/ -> ../shared      junction, ignorada no git
launcher/             projeto Godot B — fora da partida
  scripts/app/        pilha de telas, router
  scripts/services/   ApiClient, Auth, Queue, GameProcess, SettingsStore, Catalog, Profile, History
  scripts/screens/    login, lobby, perfil, heróis, compêndio (bestiário e forja), arena & mapa, histórico, configurações
  shared/ -> ../shared
shared/               comum, sem project.godot: core/, data/, resources/, assets/, ui/theme, ui/components, test/
backend/              NestJS + Postgres (auth, users, matchmaking, orchestrator, matches; telemetria só no MVP4)
art/                  fontes .blend (Blender) — nunca importadas pelo Godot; exporta .glb para shared/assets/ (ADR-0005)
infra/                Docker do game server, compose, deploy
site/                 site público (landing "Loot Start", React + Vite, GitHub Pages) — dados extraídos em build de shared/ e docs/roadmap/ (ADR-0017)
tools/                scripts PowerShell (test, run, link-shared, soak, pacote) e geradores em .gd (arena, ui, vfx, perf), roadmap em .mjs
docs/                 ver "Documentação do projeto"
```

## Comandos (PowerShell, na raiz)

| O quê | Comando |
|---|---|
| Testes (game + shared) | `.\tools\test.ps1 -Module game` |
| Testes (launcher + shared) | `.\tools\test.ps1 -Module launcher` |
| Testes (backend) | `pnpm -C backend test` |
| Junctions de `shared/` | `.\tools\link-shared.ps1` (uma vez por clone) |
| Servidor local | `.\tools\run-server.ps1` |
| Treino offline vs bot | `& $env:GODOT_PATH --path game -- --offline --bot` |
| Launcher | `& $env:GODOT_PATH --path launcher` (em dev, `-- --api=<url> --game-path=... --game-project=...`; ver `README.md`) |
| 2 clientes (2º em autopilot) | `.\tools\run-clients.ps1 -Autopilot` |
| Servidor Docker (+100 ms, 2% perda) | `$env:NETEM_DELAY_MS=100; $env:NETEM_LOSS_PCT=2; docker compose -f infra/docker-compose.yml up --build` |
| Editor | `& $env:GODOT_PATH -e --path game` ou `--path launcher` |
| Roadmap público | `.\tools\build-roadmap.ps1` (gera `docs/roadmap/index.html`) |
| Soak (N partidas bot × bot headless; obrigatório nas fatias que mexem em servidor, FSM, input ou herói) | `.\tools\soak.ps1 -Count 50 -Parallel 8` (`-Require <herói>` para herói novo) |
| Medição de rede (servidor em Docker com netem + 2 clientes) | `.\tools\net-measure.ps1 -OutDir logs\<nome> -DelayMs 100 -LossPct 2` |
| Frame time e captura só do viewport | `& $env:GODOT_PATH --path game --resolution 1920x1080 -s <repo>/tools/perf/frametime_probe.gd -- --offline --bot --autopilot=bot --out=<saida> [--shot=<png>]` |
| Bake do lightmap da arena | `.\tools\bake-lightmap.ps1` |
| Pacote ZIP do jogo | `.\tools\build-package.ps1 -ApiUrl <url> -Version v0.x.y` |
| Site público | `pnpm -C site install` (uma vez) · `pnpm -C site dev` · `pnpm -C site test` · `pnpm -C site build` |

- Para linha de comando use o `*_console.exe` (`$env:GODOT_PATH -replace '\.exe$','_console.exe'`); o `.exe` principal não imprime no terminal.
- No PowerShell 5.1, stderr de executável nativo vira exceção com `$ErrorActionPreference='Stop'` — use `'Continue'` ao chamar o Godot.
- godot-mcp: se o jogo crashar, `get_debug_output` perde a saída; rode pelo terminal para ver o erro.

## Assets 3D (Blender — ADR-0005)

- Use o **Blender sempre que necessário** para criação (arte própria), acabamento, ajustes (escala, pivô, origem, cor, troca de peças dos packs CC0) e rascunhos (blockout de arena e peças). O PI não modela: o Claude opera o Blender pelo **Blender MCP**; a verificação visual é do PI.
- Fonte `.blend` em `art/`. Em `shared/assets/` só entra glTF: pack CC0 como vem; o que passou pelo Blender, exportado em `.glb`. Nunca coloque `.blend` em `game/`, `launcher/` ou `shared/` (importação de `.blend` desligada no `project.godot`).
- Colisão, navegação e occluder pelos sufixos de nome do importador: `-col`, `-convcol`, `-colonly`, `-convcolonly`, `-navmesh`, `-occ`, `-occonly`; `-noimp` remove nó auxiliar; `-loop` em animação de laço.
- Asset novo ou alterado passa pela cena de alinhamento (PRD §11).
- Estilo (ADR-0006): personagens e props dos packs CC0 ficam como vêm (faces planas, cor por UV no atlas do KayKit `shared/assets/kaykit/medieval_hexagon/hexagons_medieval.png`). Cenário próprio em `shared/assets/rrb/` pode ter bevel de 1–2 segmentos, smooth shading por ângulo e bake de AO/curvatura (máscara em UV2); terreno, rocha, muralha e madeira usam texturas PBR CC0 de `shared/assets/textures/` (F40, F73; licenças em `shared/assets/LICENSES.md`), o resto tem cor-base pelo atlas. **Toon/outline foi abandonado** (PI, F39, 2026-10-10): não aplique cel-shading nem contorno. Exceção à regra "como vêm": o Ocultista, com atlas próprio e capuz (ADR-0016), e o Berserker, com elmo de chifres (F75). Referência de orçamento: prop/cenário 50–800 triângulos, personagem 500–3.000. Conferir a silhueta na distância da câmera do jogo.
- **Arena nova (ADR-0030, PI 2026-10-20; F94–F96):** o cenário da arena segue o estilo Eternal Return do spike F84. Isso vale para castelo, casas, pontes, rochas, rio, piso, props de borda e folhagem. Ele é feito pelo Claude no Blender por script, com proporções reais, bevel e PBR por UV planar em metros (≤ 2K, Poly Haven/ambientCG CC0). A cor de vértice traz a sujeira e a variação, sem cor-base pelo atlas. A folhagem usa cartões de folha com alpha scissor e vento (`shared/shaders/foliage_wind.gdshader`); o mato alto balança no `tall_grass.gdshader`. Orçamento: até 1.600 triângulos por objeto (peça grande partida) e frame time medido em toda fatia. Kit: `art/arena/build_castle_kit.py` → `shared/assets/rrb/arena/kit/`; materiais em `shared/resources/materials/kit/`, texturas em `shared/assets/textures/kit/`.
- Quando a colisão vem do código (medidas da SPEC), a malha visual cobre a colisão — nunca menor, senão vira parede invisível. Não use convenções `COL_`/`UCX_` (Unreal/Unity): no Godot valem os sufixos acima.
- Arte própria exportada em `shared/assets/rrb/<área>/`; fonte em `art/<área>/`.
- MCP: modo interativo exige o Blender aberto com o servidor do addon ligado (porta 9876); modo em segundo plano (`*_for_cli`) usa `BLENDER_PATH`. O MCP executa código sem proteção (risco aceito pelo PI): trabalhe só sobre arquivos versionados.

## Regras de código GDScript (obrigatórias)

1. **Tipagem estática sempre.** Membros, constantes, parâmetros e retornos com tipo explícito (`var score: int = 0`, `func take_damage(amount: int) -> void:`). Em variáveis locais, `:=` é aceito quando o tipo é óbvio pelo lado direito (`var peer := ENetMultiplayerPeer.new()`); se o lado direito for `Variant`, tipo explícito (`var hit: Variant = ...`). Laços tipados: `for action: String in actions:`. Arrays tipados: `Array[Player]`. O projeto trata `untyped_declaration` como **erro**.
2. **Nomenclatura oficial Godot:** `snake_case` para funções, variáveis, arquivos e sinais (sinais no passado: `health_changed`, `died`); `PascalCase` para `class_name`, nós e enums; `SCREAMING_SNAKE_CASE` para constantes e valores de enum; prefixo `_` para membros privados e callbacks `_on_<origem>_<sinal>`. Um `class_name` por arquivo, arquivo com o mesmo nome em snake_case.
3. **Sintaxe Godot 4:** `@onready`, `@export`, `@export_range`, `@rpc`, `await` (nunca `yield`), `Node3D`/`CharacterBody3D` (nunca `Spatial`/`KinematicBody`), `signal.connect(callable)` (nunca `connect("sig", obj, "method")`).
4. **Componentes e baixo acoplamento.** "Chama para baixo, sinaliza para cima": o pai chama métodos dos filhos; o filho emite sinais que o pai conecta. Nada de `get_node()` com caminhos longos para nós distantes; use sinais, grupos ou referências exportadas. Autoloads só para sistemas realmente globais, e nunca guardando referência a nós de cena.
5. **Performance com medição.** Object pooling para instâncias frequentes (projéteis, VFX, números de dano) — não para tudo. Sem alocação em `_process`/`_physics_process`/`_rollback_tick` quentes (reuse arrays). Desative `set_process(false)` quando ocioso. Otimização só com número do profiler antes e depois.

Ordem dentro do arquivo: `class_name` → `extends` → doc `##` → constantes/enums → sinais → `@export` → públicas → privadas → `@onready` → métodos virtuais (`_ready`, `_process`…) → públicos → privados → callbacks `_on_*`.

## Regras de rede (netfox)

- **Toda regra de jogo roda no servidor.** O cliente só envia input.
- Estado de gameplay = *state properties* do `RollbackSynchronizer`, simulado em `_rollback_tick(delta, tick, is_fresh)`. Não mexa nesse estado em `_process`/`_physics_process`.
- **Efeito sobre outro node (dano, empurrão, lentidão) não usa `NetworkRollback.mutate`**: no netfox 1.35.3 a mudança se perde quando o alvo é ressimulado. Padrão do projeto: o atacante registra o efeito num *ledger* fora do estado (`HitLedger`, só no servidor) e o **alvo aplica no próprio `_rollback_tick`** (ADR-0001, aprendizado #5).
- Node sem input no tick (jogador desconectado) **não é simulado nem transmitido** pelo servidor com `enable_prediction=false`; quem precisa sofrer dano/zona sem input tem de ter input sintetizado pelo servidor (ver `ARCHITECTURE-GAME.md` §6).
- Movimento: `velocity *= NetworkTime.physics_factor` antes de `move_and_slide()` e divida depois.
- Input só por subclasses de `BaseNetInput` (broadcast desligado). `@rpc` cru apenas para eventos discretos fora da simulação (UI, ciclo de partida).
- Pooling de objetos que participam do rollback (projéteis) precisa ser compatível com a forma de spawn do netfox — confirme no addon antes de implementar.
- Antes de afirmar nome de propriedade/método do netfox, **leia o código em `game/addons/netfox`** (a API muda entre versões).

## Fluxo de trabalho

- PRD → plano → **TDD** (teste falhando → código mínimo → teste passando → commit). Regra pura vai para `scripts/core/` (só partida) ou `shared/core/` (usada também pelo Launcher) com teste GUT; o node só orquestra.
- Valores de balanceamento em Resources `.tres` em `shared/data/` (a partir de F6), não espalhados em código.
- **Telas do Launcher saem prontas, fiéis ao protótipo** da pasta em `docs/prd/telas/` (layout, acabamento, efeitos, animação); conteúdo segue as decisões; aceite lado a lado pelo PI — `docs/FRONTEND-LAUNCHER.md` §8 (decisão do PI em 2026-10-10).
- Regra de dependência entre camadas e entre módulos está em `docs/ARCHITECTURE-GAME.md` §2 e `docs/ARCHITECTURE-LAUNCHER.md` §3.2. Launcher nunca referencia netfox/ENet/cenas de arena; Game nunca referencia telas do launcher.
- Mostre a **saída real** de testes e comandos antes de dizer que algo funciona. Verificação visual (janelas do jogo) é do usuário: pare e peça.
- **O Code executa todos os comandos, em background**: servidor (`run-server.ps1`), Docker (`docker compose ... up`), clientes (`run-clients.ps1`), editor e afins. Isso inclui abrir o Docker Desktop e fechar processos de jogo ou servidor deixados por testes anteriores. O PI não digita comando; na verificação visual, o Code sobe tudo, deixa as janelas abertas e pede ao PI só o que olhar. Depois coleta os logs e encerra os processos.
- **Captura para o roadmap público** (aprovado pelo PI em 2026-10-09): ao subir servidor e clientes para a verificação visual de uma fatia e no `[GATE]` de cada MVP, o Code tira screenshot (e vídeo curto quando o que importa é movimento), registra em `docs/roadmap/` e roda `.\tools\build-roadmap.ps1`, conforme `docs/roadmap/README.md`. Vai na mesma PR.
- Commits em pt-BR, no formato `tipo(escopo): descrição` (`feat`, `fix`, `refactor`, `test`, `docs`, `chore`).
- Não adicione nada fora do PRD/plano. Achou problema no plano → pare e pergunte.
- **Não crie regras de negócio, consentimento, LGPD, aceites ou requisitos que o usuário não tenha passado.**
- Questione as ideias do usuário antes de concordar: aponte falhas, riscos e premissas frágeis. Sem bajulação.

## Referência de engine (seu conhecimento é anterior ao Godot 4.4)

Antes de usar API que possa ter mudado, consulte `docs/engine-reference/godot/`:
`VERSION.md` → `breaking-changes.md` (inclui 4.6 → 4.7) → `deprecated-apis.md` → `current-best-practices.md` → `modules/<área>.md`.
Se a API não estiver lá, diga que não verificou e confira em https://docs.godotengine.org/en/4.7/.
Para buscar scripts: `glob: "*.gd"` (o ripgrep não tem tipo `gdscript`).

## Agentes disponíveis (`.claude/agents/`)

| Agente | Quando usar |
|---|---|
| `godot-specialist` | arquitetura de cenas/nós, autoloads, project settings, export |
| `godot-gdscript-specialist` | revisão de GDScript: tipagem, sinais, padrões (FSM, Resources) |
| `godot-shader-specialist` | shaders Godot, visual shaders, partículas |
| `network-programmer` | replicação, predição/rollback, banda, matchmaking |

São adaptados do Claude-Code-Game-Studios (ver `.claude/THIRD_PARTY_NOTICES.md`). Eles pedem aprovação antes de escrever arquivos; durante a execução de um plano já aprovado, o plano vale como aprovação para os arquivos que ele lista.

## Documentação do projeto

- `docs/DEVELOPMENT.md` — Documento de ordem de execução e status por item (atualize a cada entrega junto com STATUS.md).
- `docs/ARCHITECTURE-GAME.md` — Módulo Game: fronteira, camadas (`core` → `net` → `match` → `ui`), FSM da partida, modo offline, dados, resiliência, testes.
- `docs/ARCHITECTURE-LAUNCHER.md` — Módulo Launcher (cliente Godot + backend NestJS): serviços, telas, backend, fluxo de partida, **contrato Launcher ↔ Game** (§5), resiliência, testes.
- `docs/DECISIONS.md` — Índice de ADRs e decisões do PRD (ler antes de propor mudança estrutural). ADRs em `docs/adr/`.
- `docs/CONVENTION.md` — Documento de domínio: entidades, estados, invariantes e regras de negócio (o coração do produto). Números: GDB.
- `docs/FRONTEND-LAUNCHER.md` — Contrato de engenharia da interface (Godot `Control` + Theme): stack fixada, tipagem, padrão de tela, 5 estados, performance, prova por tela. Toda tarefa de UI (Launcher **e** HUD) começa por ele.
- `docs/design-system/DESIGN-SYSTEM-LAUNCHER.md` + `TOKENS.md`, `COMPONENTS.md`, `PATTERNS.md`, `DEBITO.md` — contrato da verdade para aparência e comportamento visual (Launcher e HUD).
- `docs/prd/mvp/MVP-0..5.md` — um por marco, com as fatias (Slice N.M) e o critério de pronto.
- `docs/GITHUB.md` — Documento de referencia das melhores praticas de commits, merges, branchs.
- `docs/PRS.md` — Boas práticas de pull request, rotina de revisão e **métricas do fluxo** (DORA, tamanho e idade de PR, rodadas de CI).
- `docs/CI-PR.md`— Documento política de PR rápida: jobs paralelos, gate único, medição de duração e limites. Melhores praticas do GitHub
- `docs/STATUS.md` — Kanban/roadmap deste projeto + **Índice Fatia ↔ SPEC** (fonte única da numeração). Prosa curta, sem detalhe.
- `docs/STATUS-ARQUIVO.md` — Documento histórico detalhado que complementa o STATUS.md: prosa longa mora aqui, com detalhe.
- `docs/APRENDIZADOS.md` — Consolidação da seção **Aprendizado** dos comentários de encerramento, mantida pelo Cowork. Curto, com teto e regra de promoção: leitura obrigatória do Code no passo 1 de todo card.
- `docs/FORA-DE-ESCOPO.md` — Fonte única dos itens adiados ou excluídos por MVP, com motivo, destino e gatilho de retorno.
- `docs/RASTREABILIDADE.md` — Matriz normativa que prova para onde cada requisito aprovado foi: mantido, transferido, adiado ou excluído. Ausência na matriz bloqueia aprovação documental.
- `docs/SITE.md` — Site público "Loot Start" (`site/`): stack, de onde vem cada dado, marca, comandos, deploy no GitHub Pages e CI. Decisão: ADR-0017.
- `docs/roadmap/` — Roadmap público (sócios, playtesters, público): `historia.json` autoral + `index.html` gerado. Estado vem das Issues e do `STATUS.md`, nunca escrito à mão. Ver `docs/roadmap/README.md`.
- `docs/evidencias/f<n>/` — evidência de aceite por fatia (capturas, frame time, logs de soak e de rede); `docs/superpowers/` — planos e specs de trabalho.
- `docs/PRIVACIDADE.md` — Registro não normativo de achados sobre privacidade, proteção de dados, LGPD e consentimentos, com contexto de origem. Não é citado por SPEC e não produz requisito ou aceite antes da revisão do PI.